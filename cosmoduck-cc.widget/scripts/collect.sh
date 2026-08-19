#!/bin/bash
# Cosmoduck · Claude Code — token usati nella finestra di sessione (5h) e in quella settimanale.
# Legge i transcript locali in ~/.claude/projects/<progetto>/<sessione>.jsonl:
# ogni riga "assistant" porta timestamp + message.usage + message.model.
#
# Le percentuali REALI arrivano da ~/.claude/cosmoduck-ratelimits.json, che scrive
# scripts/statusline.sh se lo configuri come "statusLine" in ~/.claude/settings.json
# (vedi README). Quando quella cache manca o e' scaduta si ricade sulla stima locale
# calcolata sui budget configurabili qui sotto — nei transcript non esiste alcun
# campo rate-limit, quindi senza statusline la quota vera non e' ricavabile.
#
# Anche Claude Code lanciato dall'app desktop scrive in ~/.claude, e se gira su un
# altro login la sua quota non c'entra nulla con quella del terminale. I transcript
# non registrano l'account ma registrano l'entrypoint ("cli" / "claude-desktop"),
# ed e' su quello che si filtra: vedi ENTRYPOINTS qui sotto.
export LC_ALL=C PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# ─── configurazione ────────────────────────────────────────────────────────────
SESSION_BUDGET=${SESSION_BUDGET:-1000000}     # token per finestra di sessione (5h)
WEEK_BUDGET=${WEEK_BUDGET:-10000000}          # token per finestra settimanale
SESSION_HOURS=${SESSION_HOURS:-5}             # durata finestra di sessione
WEEK_ANCHOR_DOW=${WEEK_ANCHOR_DOW:-0}         # giorno reset settimanale (0=lun … 6=dom)
WEEK_ANCHOR_HOUR=${WEEK_ANCHOR_HOUR:-0}       # ora reset settimanale (0-23, ora locale)
# Metrica: "bill" = input fresco + cache_creation + output (esclude i cache_read, che
# dominerebbero il totale di 100x falsando la lettura). "tot" include tutto.
METRIC=${METRIC:-bill}
# Per quanti secondi la cache dei limiti reali resta "live" dopo l'ultimo passaggio
# della statusline. Oltre la soglia il valore e' ancora un limite inferiore valido
# (dentro una finestra la quota puo' solo salire) ma viene marcato come vecchio.
LIVE_TTL=${LIVE_TTL:-900}
# Etichetta libera per ricordarti quale login sta contando (es. "perso", "lavoro").
# Claude Code non passa l'account alla statusline e ~/.claude.json e' condiviso con
# l'app desktop, quindi non e' deducibile: se la vuoi, scrivila qui. Vuoto = nascosta.
ACCOUNT_LABEL=${ACCOUNT_LABEL:-}
# Quali sessioni contare, per entrypoint: "cli" = solo Claude Code da terminale,
# "cli claude-desktop" = anche quello lanciato dall'app. Stringa vuota = nessun
# filtro (":-" no: tratterebbe il vuoto come non impostato e rimetterebbe "cli").
ENTRYPOINTS=${ENTRYPOINTS-cli}
# ───────────────────────────────────────────────────────────────────────────────

PY=/usr/bin/python3
[ -x "$PY" ] || PY=$(command -v python3 2>/dev/null)
if [ -z "$PY" ]; then
  echo '{"err":"nopython"}'
  exit 0
fi

SESSION_BUDGET=$SESSION_BUDGET WEEK_BUDGET=$WEEK_BUDGET SESSION_HOURS=$SESSION_HOURS \
WEEK_ANCHOR_DOW=$WEEK_ANCHOR_DOW WEEK_ANCHOR_HOUR=$WEEK_ANCHOR_HOUR METRIC=$METRIC \
LIVE_TTL=$LIVE_TTL ACCOUNT_LABEL="$ACCOUNT_LABEL" ENTRYPOINTS="$ENTRYPOINTS" \
"$PY" - <<'PYEOF'
import os, sys, json, glob, time, datetime as dt

ROOT = os.path.expanduser("~/.claude/projects")
SESSION_BUDGET   = max(1, int(os.environ.get("SESSION_BUDGET", 1000000)))
WEEK_BUDGET      = max(1, int(os.environ.get("WEEK_BUDGET", 10000000)))
SESSION_HOURS    = max(1, int(os.environ.get("SESSION_HOURS", 5)))
WEEK_ANCHOR_DOW  = int(os.environ.get("WEEK_ANCHOR_DOW", 0)) % 7
WEEK_ANCHOR_HOUR = int(os.environ.get("WEEK_ANCHOR_HOUR", 0)) % 24
METRIC           = os.environ.get("METRIC", "bill")
LIVE_TTL         = max(0, int(os.environ.get("LIVE_TTL", 900)))
ENTRYPOINTS      = set(w for w in os.environ.get("ENTRYPOINTS", "cli").split() if w)

now     = dt.datetime.now(dt.timezone.utc)
now_loc = now.astimezone()

# Inizio della finestra settimanale corrente (ancorata a giorno+ora locali).
anchor = now_loc.replace(hour=WEEK_ANCHOR_HOUR, minute=0, second=0, microsecond=0)
anchor -= dt.timedelta(days=(now_loc.weekday() - WEEK_ANCHOR_DOW) % 7)
if anchor > now_loc:
    anchor -= dt.timedelta(days=7)
week_start = anchor.astimezone(dt.timezone.utc)
week_reset = anchor + dt.timedelta(days=7)

# Solo i file toccati di recente possono contenere record recenti.
scan_from = min(week_start, now - dt.timedelta(hours=SESSION_HOURS))
mtime_cut = scan_from.timestamp() - 3600

rows = []          # (timestamp, bill, tot)
seen = set()       # dedup per requestId: i retry ripetono lo stesso record
last_model = None
last_model_ts = None
last_effort = None

for path in glob.glob(os.path.join(ROOT, "*", "*.jsonl")):
    try:
        if os.path.getmtime(path) < mtime_cut:
            continue
    except OSError:
        continue
    try:
        fh = open(path, "r", errors="replace")
    except OSError:
        continue

    # Righe e modello di QUESTO transcript, tenute da parte finche' non si sa da
    # dove girava la sessione: l'entrypoint sta sui record, non nel nome del file.
    f_rows, f_entry = [], None
    f_model = f_model_ts = f_effort = None

    with fh:
        for line in fh:
            if '"output_tokens"' not in line:
                continue
            try:
                d = json.loads(line)
            except ValueError:
                continue
            ts = d.get("timestamp")
            msg = d.get("message") or {}
            u = msg.get("usage")
            if not ts or not u:
                continue
            try:
                t = dt.datetime.fromisoformat(ts.replace("Z", "+00:00"))
            except ValueError:
                continue
            if t < scan_from:
                continue
            rid = d.get("requestId") or d.get("uuid")
            if rid in seen:
                continue
            seen.add(rid)

            if f_entry is None:
                f_entry = d.get("entrypoint")

            model = msg.get("model")
            if model and not model.startswith("<") and (f_model_ts is None or t > f_model_ts):
                # "effort" e' un campo top-level del record, non dentro message.
                f_model, f_model_ts = model, t
                f_effort = d.get("effort")

            fresh_tok = (u.get("input_tokens") or 0) + (u.get("cache_creation_input_tokens") or 0)
            out       = u.get("output_tokens") or 0
            cached    = u.get("cache_read_input_tokens") or 0
            f_rows.append((t, fresh_tok + out, fresh_tok + out + cached))

    # I transcript non registrano l'account, ma registrano l'entrypoint: "cli" per
    # il terminale, "claude-desktop" per Claude Code lanciato dall'app. Se i due
    # girano su login diversi e' la stessa distinzione, e senza filtro la stima
    # sommerebbe quote di account diversi. Entrypoint sconosciuto = si tiene, per
    # non azzerare tutto se un domani il campo cambia nome.
    if ENTRYPOINTS and f_entry is not None and f_entry not in ENTRYPOINTS:
        continue

    rows.extend(f_rows)
    if f_model and (last_model_ts is None or f_model_ts > last_model_ts):
        last_model, last_model_ts, last_effort = f_model, f_model_ts, f_effort

rows.sort(key=lambda r: r[0])
idx = 2 if METRIC == "tot" else 1

# ── finestra di sessione ──────────────────────────────────────────────────────
# Riproduce la semantica di Claude Code: la finestra parte al primo messaggio e
# dura SESSION_HOURS; il messaggio successivo alla scadenza ne apre una nuova.
span = dt.timedelta(hours=SESSION_HOURS)
blk_start, blk_used = None, 0
for t, bill, tot in rows:
    if blk_start is None or t >= blk_start + span:
        blk_start, blk_used = t, 0
    blk_used += (tot if idx == 2 else bill)

if blk_start is None or now >= blk_start + span:
    sess_used, sess_reset = 0, None      # nessuna sessione attiva
else:
    sess_used, sess_reset = blk_used, (blk_start + span).astimezone()

week_used = sum(r[idx] for r in rows if r[0] >= week_start)

hour_start = now - dt.timedelta(hours=1)
hour_used = sum(r[idx] for r in rows if r[0] >= hour_start)

def pct(used, budget):
    # Intero: la quota reale ha questa granularita' e cosi' widget e statusline
    # non mostrano mai due numeri diversi per lo stesso dato.
    return int(round(min(100.0, 100.0 * used / budget)))

def human(n):
    for lim, suf, div in ((1e9, "B", 1e9), (1e6, "M", 1e6), (1e3, "K", 1e3)):
        if n >= lim:
            v = n / div
            return ("%.1f%s" % (v, suf)) if v < 100 else ("%.0f%s" % (v, suf))
    return str(int(n))

DOW = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")

def clock(t):
    return "--:--" if t is None else t.strftime("%H:%M")

def stamp(t):
    if t is None:
        return "--"
    same_day = t.date() == now_loc.date()
    return t.strftime("%H:%M") if same_day else "%s %s" % (DOW[t.weekday()], t.strftime("%H:%M"))

def short(m):
    if not m:
        return "n/d"
    s = m[7:] if m.startswith("claude-") else m
    s = s.split("-2")[0]                          # via la data-versione finale
    parts = [p for p in s.split("-") if p]
    if len(parts) >= 2:
        fam, ver = parts[0], ".".join(parts[1:])
        return "%s %s" % (fam.capitalize(), ver)
    return s.capitalize()

# ── limiti reali dalla cache della statusline ────────────────────────────────
# Ha la precedenza sulla stima: e' la quota vera dell'account. Una finestra gia'
# scaduta (now >= resets_at) viene ignorata, perche' il valore in cache si
# riferisce a un ciclo ormai chiuso.
#
# Non si prova a stabilire A QUALE account appartenga la lettura: Claude Code non
# passa l'account alla statusline, e ~/.claude.json e' condiviso fra la CLI e
# l'app Claude Desktop (ci si trovano i config cache di piu' login), quindi
# qualsiasi etichetta ricavata da li' sarebbe una supposizione. In compenso la
# cache la scrive solo la statusline, che gira solo dentro una sessione CLI:
# l'app desktop non la tocca mai. Se cambi login nel terminale, la lettura del
# login precedente resta valida fino al suo reset e poi decade da sola; nel
# frattempo l'eta' qui sotto dice quanto e' vecchia.
live = {}
cache_age = None
try:
    with open(os.path.expanduser("~/.claude/cosmoduck-ratelimits.json")) as fh:
        raw = json.load(fh)

    # La statusline aggiornata scrive solo da sessioni ammesse, ma una cache
    # lasciata li' da una versione precedente puo' venire da chiunque: se e'
    # marcata e non e' ammessa, si scarta. Non marcata = si accetta (formato
    # vecchio, viene rimpiazzata al primo render).
    entry = raw.get("entrypoint")
    if ENTRYPOINTS and entry is not None and entry not in ENTRYPOINTS:
        raise ValueError("cache scritta da una sessione esclusa")

    cap = raw.get("captured_at")
    if cap is not None:
        cache_age = max(0, int(now.timestamp() - float(cap)))

    cached = raw.get("rate_limits") or {}
    for key, win in (("session", "five_hour"), ("week", "seven_day")):
        w = cached.get(win) or {}
        p, r = w.get("used_percentage"), w.get("resets_at")
        if p is None or r is None or now.timestamp() >= r:
            continue
        live[key] = (int(round(float(p))),
                     dt.datetime.fromtimestamp(r, dt.timezone.utc).astimezone())
except (OSError, ValueError, AttributeError, TypeError):
    pass

# Un dato reale ma non piu' rinfrescato resta un limite inferiore attendibile
# (dentro una finestra la quota puo' solo salire), pero' va distinto dal live:
# nel frattempo puo' essere cresciuto per consumi che non passano da questa
# statusline — p.es. Claude Desktop, o una sessione chiusa da ore.
fresh = cache_age is not None and cache_age <= LIVE_TTL

# "src": da dove viene la percentuale — "live" quota reale aggiornata, "stale"
# quota reale ma vecchia, "est" stima locale sui budget configurati.
src = "live" if fresh else "stale"

sess = {
    "used":   sess_used,
    "human":  human(sess_used),
    "pct":    pct(sess_used, SESSION_BUDGET),
    "reset":  clock(sess_reset),
    "active": sess_reset is not None,
    "src":    "est",
    "live":   False,
}
if "session" in live:
    p, r = live["session"]
    sess.update(pct=p, reset=clock(r), active=True, src=src, live=fresh)

week = {
    "used":  week_used,
    "human": human(week_used),
    "pct":   pct(week_used, WEEK_BUDGET),
    "reset": stamp(week_reset),
    "src":   "est",
    "live":  False,
}
if "week" in live:
    p, r = live["week"]
    week.update(pct=p, reset=stamp(r), src=src, live=fresh)

print(json.dumps({
    "model":  short(last_model),
    "modelId": last_model or "",
    "effort": (last_effort or "") if isinstance(last_effort, str) else (
        (last_effort or {}).get("level") or ""),
    "session": sess,
    "week": week,
    "hour": {
        "used":  hour_used,
        "human": human(hour_used),
    },
    "label": os.environ.get("ACCOUNT_LABEL", ""),
    "age":   cache_age,
    "metric": METRIC,
}))
PYEOF
