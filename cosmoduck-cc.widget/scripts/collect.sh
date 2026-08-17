#!/bin/bash
# Cosmoduck · Claude Code — token usati nella finestra di sessione (5h) e in quella settimanale.
# Legge i transcript locali in ~/.claude/projects/<progetto>/<sessione>.jsonl:
# ogni riga "assistant" porta timestamp + message.usage + message.model.
#
# NOTA: la quota reale dell'account NON e' disponibile in locale (nei transcript non
# esiste alcun campo rate-limit). Le percentuali sono quindi calcolate su budget
# configurabili qui sotto: tarali guardando /usage dentro Claude Code.
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
# ───────────────────────────────────────────────────────────────────────────────

PY=/usr/bin/python3
[ -x "$PY" ] || PY=$(command -v python3 2>/dev/null)
if [ -z "$PY" ]; then
  echo '{"err":"nopython"}'
  exit 0
fi

SESSION_BUDGET=$SESSION_BUDGET WEEK_BUDGET=$WEEK_BUDGET SESSION_HOURS=$SESSION_HOURS \
WEEK_ANCHOR_DOW=$WEEK_ANCHOR_DOW WEEK_ANCHOR_HOUR=$WEEK_ANCHOR_HOUR METRIC=$METRIC \
"$PY" - <<'PYEOF'
import os, sys, json, glob, time, datetime as dt

ROOT = os.path.expanduser("~/.claude/projects")
SESSION_BUDGET   = max(1, int(os.environ.get("SESSION_BUDGET", 1000000)))
WEEK_BUDGET      = max(1, int(os.environ.get("WEEK_BUDGET", 10000000)))
SESSION_HOURS    = max(1, int(os.environ.get("SESSION_HOURS", 5)))
WEEK_ANCHOR_DOW  = int(os.environ.get("WEEK_ANCHOR_DOW", 0)) % 7
WEEK_ANCHOR_HOUR = int(os.environ.get("WEEK_ANCHOR_HOUR", 0)) % 24
METRIC           = os.environ.get("METRIC", "bill")

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

            model = msg.get("model")
            if model and not model.startswith("<") and (last_model_ts is None or t > last_model_ts):
                last_model, last_model_ts = model, t

            fresh  = (u.get("input_tokens") or 0) + (u.get("cache_creation_input_tokens") or 0)
            out    = u.get("output_tokens") or 0
            cached = u.get("cache_read_input_tokens") or 0
            rows.append((t, fresh + out, fresh + out + cached))

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
    return round(min(100.0, 100.0 * used / budget), 1)

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

print(json.dumps({
    "model":  short(last_model),
    "modelId": last_model or "",
    "session": {
        "used":   sess_used,
        "human":  human(sess_used),
        "pct":    pct(sess_used, SESSION_BUDGET),
        "reset":  clock(sess_reset),
        "active": sess_reset is not None,
    },
    "week": {
        "used":  week_used,
        "human": human(week_used),
        "pct":   pct(week_used, WEEK_BUDGET),
        "reset": stamp(week_reset),
    },
    "hour": {
        "used":  hour_used,
        "human": human(hour_used),
    },
    "metric": METRIC,
}))
PYEOF
