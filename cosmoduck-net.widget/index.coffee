# Cosmoduck · Rete — Übersicht (legacy, lockable & draggable)
# SSID (icona feather) + Down/Up con sparkline SVG.

# ▼ cosmoduck-theme ────────────────────────────────────────────────────────────
# Non modificarlo qui: il blocco e' uguale in tutti i widget del set e lo scrive
# theme/sync.sh, copiandolo da theme/widget-block.coffee.in insieme a
# scripts/theme.sh e scripts/palette.jxa.
#
# I colori di questo widget, e il retro da cui si scelgono. Ogni widget ha i
# suoi, indipendenti dagli altri:
#   AUTO     ricavati dal wallpaper in uso (scripts/theme.sh), ogni 5 secondi
#   CUSTOM   una tinta per i segni, una per il vetro, e quanto sono cariche
#   CLASSIC  il blu Cosmoduck originale
# La scelta sta nel localStorage di Ubersicht alla chiave <prefisso>_theme,
# accanto a posizione e lucchetto.
#
# Il retro si apre dalla (i) che compare in basso a destra passando sopra la
# card, come nei widget della Dashboard di Tiger. La card gira in due mezzi
# giri -- fino a taglio, cambio di faccia, poi il resto -- ruotando se stessa e
# non una faccia montata al contrario: cosi' non servono ne' preserve-3d ne'
# backface-visibility, le due cose con cui il backdrop-filter del vetro ha i
# suoi guai in WebKit.
CDT = do ->
  # ruolo: [saturazione, luminosita', scarto di tinta] -- misurati sui colori
  # originali, che non stanno su una tinta sola: i tre toni scuri sono una
  # decina di gradi piu' in la', ed e' quello scarto a dargli il freddo. Le
  # luminosita' non cambiano mai, qualunque tinta si scelga: sono loro a
  # decidere se il testo si legge sul vetro.
  TEMA =
    accent: [0.70, 0.63,  0]   # #5DADE2
    bright: [0.70, 0.81,  0]   # #AED6F1
    mid:    [0.70, 0.72,  0]   # #85C1E9
    deep:   [0.61, 0.40,  0]   # #2874A6
    shadow: [0.51, 0.25, 11]   # #1F3A5F
    text:   [0.41, 0.85,  4]   # #C8D9E8
    ink:    [0.39, 0.10, 11]   # #0F1722
    glass:  [0.36, 0.10,  8]   # rgba(16,24,34,.55)
  # I segni in primo piano -- numeri, icone, archi, bordi -- prendono la tinta
  # dell'accento, il resto quella del supporto: vetro, inchiostro, ombre. Se il
  # wallpaper ha una scritta chiara, i segni di contorno e il testo si
  # schiariscono fino al neutro, che e' il colore di quella scritta.
  ACCENT_ROLES = ['accent', 'bright', 'mid', 'deep']
  LETTER_ROLES = ['bright', 'mid', 'text']
  LETTER_SAT = 0.25
  BASE_HUE = 204
  SAT_MAX = 1.3
  POLL = 5000

  # CLASSIC e' scritto per esteso invece che ricomposto dalla tabella: deve
  # essere il blu di sempre al bit, e deve vincere anche sulle variabili che un
  # vecchio widget tema, se e' rimasto installato, scrive ancora su <html>.
  CLASSIC =
    '--cd-accent':     '#5DADE2'
    '--cd-bright':     '#AED6F1'
    '--cd-mid':        '#85C1E9'
    '--cd-deep':       '#2874A6'
    '--cd-shadow':     '#1F3A5F'
    '--cd-text':       '#C8D9E8'
    '--cd-ink':        '#0F1722'
    '--cd-glass':      'rgba(16,24,34,0.55)'
    '--cd-border':     'rgba(93,173,226,0.22)'
    '--cd-fill':       'rgba(93,173,226,0.18)'
    '--cd-rule':       'rgba(93,173,226,0.14)'
    '--cd-rule-faint': 'rgba(93,173,226,0.12)'
    '--cd-track':      'rgba(31,58,95,0.55)'

  clamp = (v, lo, hi) -> Math.min(hi, Math.max(lo, v))

  rgb = (h, s, l) ->
    h = ((h % 360) + 360) % 360
    s = clamp(s, 0, 1)
    a = s * Math.min(l, 1 - l)
    f = (n) ->
      k = (n + h / 30) % 12
      Math.round(255 * (l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1))))
    [f(0), f(8), f(4)]

  hex = (c) -> '#' + (('0' + v.toString(16)).slice(-2) for v in c).join('').toUpperCase()
  rgba = (c, a) -> "rgba(#{c.join(',')},#{a})"

  # p: tinta e scala dei segni (hue, satScale), del supporto (fieldHue,
  # fieldScale), e letters se il wallpaper ha una scritta chiara.
  compose = (p) ->
    c = {}
    for role, t of TEMA
      [h, sc] = if p.letters and role in LETTER_ROLES
        [p.fieldHue, p.fieldScale * LETTER_SAT]
      else if role in ACCENT_ROLES
        [p.hue, p.satScale]
      else
        [p.fieldHue, p.fieldScale]
      c[role] = rgb(h + t[2], clamp(t[0] * sc, 0.05, 0.95), t[1])
    '--cd-accent':     hex(c.accent)
    '--cd-bright':     hex(c.bright)
    '--cd-mid':        hex(c.mid)
    '--cd-deep':       hex(c.deep)
    '--cd-shadow':     hex(c.shadow)
    '--cd-text':       hex(c.text)
    '--cd-ink':        hex(c.ink)
    '--cd-glass':      rgba(c.glass, 0.55)
    '--cd-border':     rgba(c.accent, 0.22)
    '--cd-fill':       rgba(c.accent, 0.18)
    '--cd-rule':       rgba(c.accent, 0.14)
    '--cd-rule-faint': rgba(c.accent, 0.12)
    '--cd-track':      rgba(c.shadow, 0.55)

  # Il wallpaper e' uno per schermo, e Ubersicht da' a ogni schermo il suo
  # documento: la lettura si fa una volta per documento e la condividono tutti
  # i widget in AUTO, invece di lanciare una shell a testa ogni cinque secondi.
  # Chi arriva mentre un altro la sta facendo si mette in coda e riceve la
  # stessa risposta. Se la lettura fallisce resta buona quella di prima.
  wallpaper = (run, cmd, cb) ->
    s = window.__cdtWallpaper ?= {at: 0, data: null, busy: 0, queue: []}
    now = Date.now()
    return cb(s.data) if s.data and now - s.at < POLL - 500
    s.queue.push(cb)
    return if s.busy and now - s.busy < 15000
    s.busy = now
    run cmd, (err, out) ->
      try
        d = JSON.parse(out)
        if d and typeof d.hue is 'number'
          s.data = d
          s.at = Date.now()
      catch
        null   # niente JSON: wallpaper illeggibile o script a meta'
      s.busy = 0
      [queue, s.queue] = [s.queue, []]
      f(s.data) for f in queue
      return

  gradient = (fn) -> "linear-gradient(90deg, #{(fn(i / 12) for i in [0..12]).join(', ')})"

  ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>'

  # Esposta per provarla da fuori: CDT.compose({hue: 30, satScale: 1,
  # fieldHue: 30, fieldScale: 1}) da' le variabili di un tema arancione.
  compose: compose

  # opts.info  dove sta la (i) e quanto e' grande, in punti: {top|bottom,
  #            left|right, size}. Di suo va in basso a destra, ma ogni widget
  #            la mette dove non copre un numero: accanto al lucchetto, sotto.
  # opts.glass true per i widget senza card (l'orologio): il retro si porta
  #            dietro il suo vetro, invece di usare quello del widget
  init: (domEl, P, run, opts = {}) ->
    $el = $(domEl)
    key = "#{P}_theme"
    cmd = "bash #{P}.widget/scripts/theme.sh"
    info = $.extend({size: 15}, opts.info or {right: 9, bottom: 9})
    # Attenzione ai nomi: CoffeeScript 1 non ha let, e una variabile di ciclo
    # scritta qui vale per tutto init, closure comprese. Un "k" qui e un "k"
    # nel cursore erano la stessa variabile, e il cursore scriveva nella chiave
    # dell'ultima variabile CSS applicata.
    place = ("#{edge}: #{info[edge]}px;" for edge in ['top', 'right', 'bottom', 'left'] when info[edge]?).join(' ')

    t = {mode: 'auto', hue: BASE_HUE, base: BASE_HUE, sat: 1}
    try
      saved = JSON.parse(localStorage.getItem(key) or 'null')
      $.extend(t, saved) if saved and typeof saved is 'object'
    save = -> try localStorage.setItem(key, JSON.stringify(t))

    auto = null        # l'ultima lettura del wallpaper vista da questo widget
    last = null
    apply = (vars) ->
      s = JSON.stringify(vars)
      return if s is last
      last = s
      domEl.style.setProperty(name, value) for name, value of vars
      # Ricordata per la prossima partenza: la lettura del wallpaper arriva
      # qualche istante dopo il widget, e nel frattempo si vedrebbe il blu.
      try localStorage.setItem("#{key}_vars", s)

    # Quello che i cursori mostrano: la scelta a mano, la lettura del wallpaper
    # o il blu di sempre. Toccarne uno fuori da CUSTOM ci passa, partendo da qui.
    shown = ->
      return {hue: t.hue, base: t.base, sat: t.sat} if t.mode is 'custom'
      return {hue: auto.hue, base: auto.fieldHue, sat: auto.satScale} if t.mode is 'auto' and auto
      {hue: BASE_HUE, base: BASE_HUE, sat: 1}

    params = ->
      if t.mode is 'custom'
        {hue: t.hue, satScale: t.sat, fieldHue: t.base, fieldScale: t.sat, letters: false}
      else if t.mode is 'auto' and auto
        {hue: auto.hue, satScale: auto.satScale, fieldHue: auto.fieldHue, fieldScale: auto.fieldScale, letters: !!auto.subject}
      else
        null

    # ── il retro ─────────────────────────────────────────────────────────────
    $el.children('.cdt-ui').remove()
    S = "##{domEl.id}"
    $el.append """
      <style class="cdt-ui">
        #{S} .cdt-info { position: absolute; #{place}
          width: #{info.size}px; height: #{info.size}px; color: var(--cd-bright, #AED6F1);
          opacity: 0; cursor: pointer; transition: opacity 0.2s; z-index: 11 }
        #{S}:hover .cdt-info { opacity: 0.55 }
        #{S} .cdt-info:hover { opacity: 1 }
        #{S} .cdt-info svg { width: 100%; height: 100%; display: block }
        #{S}.cdt-flipped > :not(.cdt-back):not(style) { visibility: hidden !important }
        #{S}.cdt-flipped { background-image: none !important }
        #{S} .cdt-back { display: none; position: absolute; top: 0; left: 0; right: 0; bottom: 0;
          box-sizing: border-box; padding: 12px 14px; flex-direction: column; justify-content: center;
          gap: 7px; z-index: 20; cursor: default; text-align: left; line-height: 1;
          font-family: 'CDAbel', -apple-system, sans-serif; font-weight: 400;
          color: var(--cd-text, #C8D9E8) }
        #{S}.cdt-flipped .cdt-back { display: flex }
        #{S} .cdt-back.glass { background: var(--cd-glass, rgba(16,24,34,0.55));
          -webkit-backdrop-filter: blur(12px) saturate(1.2); backdrop-filter: blur(12px) saturate(1.2);
          border: 1px solid var(--cd-border, rgba(93,173,226,0.22)); border-radius: 22px;
          box-shadow: inset 0 1px 0 rgba(255,255,255,0.07) }
        #{S} .cdt-h { font-size: 10px; letter-spacing: 1.5px; opacity: 0.45; margin-bottom: 1px }
        #{S} .cdt-seg { display: flex; border: 1px solid var(--cd-border, rgba(93,173,226,0.22));
          border-radius: 6px; overflow: hidden }
        #{S} .cdt-seg span { flex: 1 1 0; text-align: center; font-size: 8.8px; letter-spacing: 0.4px;
          padding: 4px 0 3px; cursor: pointer; opacity: 0.65; transition: opacity 0.15s, background 0.15s }
        #{S} .cdt-seg span + span { border-left: 1px solid var(--cd-border, rgba(93,173,226,0.22)) }
        #{S} .cdt-seg span:hover { opacity: 1 }
        #{S} .cdt-seg span.on { opacity: 1; color: var(--cd-accent, #5DADE2);
          background: var(--cd-fill, rgba(93,173,226,0.18)) }
        #{S} .cdt-row { display: flex; align-items: center; gap: 6px; height: 12px }
        #{S} .cdt-row b { width: 34px; flex: 0 0 auto; font-weight: 400; font-size: 8.8px;
          letter-spacing: 0.5px; opacity: 0.6 }
        #{S} .cdt-sl { position: relative; flex: 1 1 auto; height: 6px; border-radius: 3px;
          cursor: pointer; transition: opacity 0.15s }
        #{S} .cdt-back:not(.custom) .cdt-sl { opacity: 0.45 }
        #{S} .cdt-back:not(.custom) .cdt-sl:hover { opacity: 0.8 }
        #{S} .cdt-sl i { position: absolute; top: 50%; width: 10px; height: 10px; margin: -5px 0 0 -5px;
          box-sizing: border-box; border-radius: 50%; border: 1.5px solid var(--cd-text, #C8D9E8);
          box-shadow: 0 0 0 1px rgba(0,0,0,0.35) }
        #{S} .cdt-foot { display: flex; justify-content: flex-end; margin-top: 1px }
        #{S} .cdt-done { font-size: 8.8px; letter-spacing: 0.6px; padding: 3px 8px 2px;
          border-radius: 8px; border: 1px solid var(--cd-border, rgba(93,173,226,0.22));
          color: var(--cd-accent, #5DADE2); cursor: pointer; transition: background 0.15s }
        #{S} .cdt-done:hover { background: var(--cd-fill, rgba(93,173,226,0.18)) }
      </style>
      <div class="cdt-info cdt-ui" title="Colors">#{ICON}</div>
      <div class="cdt-back cdt-ui#{if opts.glass then ' glass' else ''}">
        <div class="cdt-h">COLORS</div>
        <div class="cdt-seg"><span data-m="auto">AUTO</span><span data-m="custom">CUSTOM</span><span data-m="classic">CLASSIC</span></div>
        <div class="cdt-row"><b>ACCENT</b><span class="cdt-sl" data-k="hue"><i></i></span></div>
        <div class="cdt-row"><b>BASE</b><span class="cdt-sl" data-k="base"><i></i></span></div>
        <div class="cdt-row"><b>SAT</b><span class="cdt-sl" data-k="sat"><i></i></span></div>
        <div class="cdt-foot"><span class="cdt-done">DONE</span></div>
      </div>
    """
    $back = $el.children('.cdt-back')

    # I binari dei cursori sono dipinti coi colori che ne uscirebbero: la tinta
    # dell'accento lungo il cerchio, quella delle ombre per il supporto, e la
    # stessa tinta dal grigio al pieno per la saturazione.
    syncBack = ->
      v = shown()
      s = clamp(0.70 * v.sat, 0.05, 0.95)
      $back.toggleClass('custom', t.mode is 'custom')
      $back.find('.cdt-seg span').each -> $(this).toggleClass('on', @getAttribute('data-m') is t.mode)
      put = (k, f, color, track) ->
        sl = $back.find(".cdt-sl[data-k=#{k}]").css('background', track)
        sl.children('i').css(left: "#{(f * 100).toFixed(2)}%", background: color)
      put 'hue', v.hue / 360, hex(rgb(v.hue, s, 0.63)),
        gradient((f) -> hex(rgb(f * 360, s, 0.63)))
      put 'base', v.base / 360, hex(rgb(v.base + 11, clamp(0.51 * v.sat, 0.05, 0.95), 0.32)),
        gradient((f) -> hex(rgb(f * 360 + 11, clamp(0.51 * v.sat, 0.05, 0.95), 0.32)))
      put 'sat', v.sat / SAT_MAX, hex(rgb(v.hue, s, 0.63)),
        gradient((f) -> hex(rgb(v.hue, clamp(0.70 * f * SAT_MAX, 0, 0.95), 0.63)))

    paint = ->
      if t.mode is 'classic'
        apply(CLASSIC)
      else if (p = params())
        apply(compose(p))
      syncBack()

    tick = ->
      return unless t.mode is 'auto' and run
      wallpaper run, cmd, (d) ->
        return unless d
        auto = d
        paint() if t.mode is 'auto'

    # ── il giro ──────────────────────────────────────────────────────────────
    # Il transform di partenza si conserva e ci si compone sopra: la card
    # dell'orologio in cima al pannello scivola fuori dal bordo proprio col
    # transform. Finito il giro la card lo annuncia con un evento, cdt:flip,
    # per chi deve saperlo.
    flip = (toBack) ->
      return if $el.hasClass('cdt-anim') or $el.hasClass('cdt-flipped') is toBack
      done = -> domEl.dispatchEvent(new CustomEvent('cdt:flip', {detail: toBack}))
      if window.matchMedia?('(prefers-reduced-motion: reduce)').matches
        $el.toggleClass('cdt-flipped', toBack)
        done()
        return
      $el.addClass('cdt-anim')
      base = domEl.style.transform or ''
      transition = domEl.style.transition
      depth = Math.max(600, domEl.offsetWidth * 3)
      turn = (deg, ms, ease) ->
        domEl.style.transition = if ms then "transform #{ms}ms #{ease}" else 'none'
        domEl.style.transform = "#{base} perspective(#{depth}px) rotateY(#{deg}deg)"
      turn(0, 0)
      domEl.offsetWidth
      turn(90, 180, 'cubic-bezier(0.55, 0, 1, 0.45)')
      setTimeout ->
        $el.toggleClass('cdt-flipped', toBack)
        turn(-90, 0)
        domEl.offsetWidth
        turn(0, 220, 'cubic-bezier(0, 0.55, 0.45, 1)')
        setTimeout ->
          domEl.style.transition = transition
          domEl.style.transform = base
          $el.removeClass('cdt-anim')
          done()
        , 240
      , 190

    # jQuery fa risalire i delegati come farebbe il browser: fermati qui, i
    # click e i mousedown del retro non arrivano al trascinamento della card.
    $el.off('.cdt')
    $el.on 'mousedown.cdt', '.cdt-ui', (e) -> e.stopPropagation()
    $el.on 'click.cdt', '.cdt-ui', (e) -> e.stopPropagation()
    $el.on 'click.cdt', '.cdt-info', -> flip(true)
    $el.on 'click.cdt', '.cdt-done', -> flip(false)

    # Passando a CUSTOM si parte dai colori che si stanno guardando, non da
    # quelli dell'ultima volta: e' il modo di dire "questo, ma un po' piu' in la'".
    toCustom = ->
      return if t.mode is 'custom'
      v = shown()
      t.hue = v.hue
      t.base = v.base
      t.sat = v.sat
      t.mode = 'custom'

    $el.on 'click.cdt', '.cdt-seg span', ->
      m = @getAttribute('data-m')
      return if m is t.mode
      if m is 'custom' then toCustom() else t.mode = m
      save()
      paint()
      tick()

    $el.on 'mousedown.cdt', '.cdt-sl', (e) ->
      e.preventDefault()
      sl = e.currentTarget
      field = sl.getAttribute('data-k')
      set = (ev) ->
        r = sl.getBoundingClientRect()
        f = clamp((ev.clientX - r.left) / r.width, 0, 1)
        toCustom()
        t[field] = if field is 'sat' then Math.round(f * SAT_MAX * 1000) / 1000 else Math.round(f * 360)
        paint()
      set(e)
      up = ->
        $(document).off('mousemove', set).off('mouseup', up)
        save()
      $(document).on('mousemove', set).on('mouseup', up)

    # ── partenza ─────────────────────────────────────────────────────────────
    if t.mode is 'auto'
      try
        cached = JSON.parse(localStorage.getItem("#{key}_vars") or 'null')
        apply(cached) if cached and typeof cached is 'object'
    paint()
    clearInterval(domEl.__cdtTimer)
    domEl.__cdtTimer = setInterval(tick, POLL)
    tick()
    return
# ▲ cosmoduck-theme ────────────────────────────────────────────────────────────

command: "bash cosmoduck-net.widget/scripts/collect.sh"
refreshFrequency: 1000

style: """
  top: 310px
  left: 12px
  width: 150px
  height: 140px
  box-sizing: border-box
  overflow: hidden
  color: var(--cd-text, #C8D9E8)
  font-family: 'CDAbel', -apple-system, sans-serif
  background: var(--cd-glass, rgba(16,24,34,0.55))
  -webkit-backdrop-filter: blur(12px) saturate(1.2)
  backdrop-filter: blur(12px) saturate(1.2)
  border-radius: 22px
  border: 1px solid var(--cd-border, rgba(93,173,226,0.22))
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.07)
  padding: 14px 0 0 18px
  user-select: none
  pointer-events: auto
  cursor: grab

  &.locked
    cursor: default

  .lock-btn
    position: absolute
    top: 10px
    right: 9px
    color: var(--cd-bright, #AED6F1)
    width: 15px
    height: 15px
    opacity: 0
    cursor: pointer
    transition: opacity 0.2s
    z-index: 10
  &:hover .lock-btn
    opacity: 0.55
  .lock-btn:hover
    opacity: 1
  .lock-btn svg
    width: 15px
    height: 15px
    display: block

  .pos-indicator
    position: absolute
    bottom: 2px
    left: 50%
    transform: translateX(-50%)
    background: rgba(0,0,0,0.6)
    color: #fff
    font-size: 8px
    padding: 2px 8px
    border-radius: 10px
    opacity: 0
    transition: opacity 0.3s
    pointer-events: none
    z-index: 10
  .dragging .pos-indicator
    opacity: 1

  .ssid
    font-size: 13px
    font-weight: 700
    color: var(--cd-accent, #5DADE2)
  .ssid .i
    font-family: 'CDFeather'
    font-weight: 400
  .lab
    font-size: 11px
    margin-top: 4px
  .spark
    margin-top: 1px
"""

render: -> """
  <style>
    @font-face{font-family:'CDFeather';src:url('cosmoduck-net.widget/fonts/feather.ttf') format('truetype');}
    @font-face{font-family:'CDAbel';src:url('cosmoduck-net.widget/fonts/Abel-Regular.ttf') format('truetype');}
  </style>
  <div class="lock-btn" id="lock-toggle"></div>
  <div class="ssid"><span class="i" id="wifi-ico"></span> : <span id="ssid">None</span></div>
  <div class="lab">Downspeed : <span id="down">0 B</span></div>
  <div class="spark" id="dspark"></div>
  <div class="lab">Upspeed : <span id="up">0 B</span></div>
  <div class="spark" id="uspark"></div>
  <div class="pos-indicator" id="coords">T: 0 L: 0</div>
"""

afterRender: (domEl) ->
  P = "cosmoduck-net"
  LOCK_SVG = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>'
  UNLOCK_SVG = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"></rect><path d="M7 11V7a5 5 0 0 1 9.9-1"></path></svg>'
  isLocked = localStorage.getItem("#{P}_locked") == 'true'
  savedTop = localStorage.getItem("#{P}_pos_top2")
  savedLeft = localStorage.getItem("#{P}_pos_left2")
  if savedTop and savedLeft
    # La posizione salvata puo' venire da uno schermo piu' grande, o da un
    # trascinamento finito oltre il bordo. Se la card non ci sta tutta nel
    # viewport corrente buttiamo via le chiavi e torniamo al posto di default
    # dello style: bloccata e fuori schermo non la si recupera piu' col mouse.
    posT = parseInt(savedTop, 10)
    posL = parseInt(savedLeft, 10)
    onScreen = not isNaN(posT) and not isNaN(posL) and
               posT >= 0 and posL >= 0 and
               posT + domEl.offsetHeight <= window.innerHeight and
               posL + domEl.offsetWidth <= window.innerWidth
    if onScreen
      domEl.style.top = savedTop
      domEl.style.left = savedLeft
    else
      localStorage.removeItem("#{P}_pos_top2")
      localStorage.removeItem("#{P}_pos_left2")

  updateLockUI = ->
    $(domEl).toggleClass('locked', isLocked)
    $(domEl).find('#lock-toggle').html(if isLocked then LOCK_SVG else UNLOCK_SVG)
  updateLockUI()

  $(domEl).find('#lock-toggle').on 'click', (e) ->
    isLocked = !isLocked
    localStorage.setItem("#{P}_locked", isLocked)
    updateLockUI()
    e.stopPropagation()

  isDragging = false
  startX = 0
  startY = 0

  $(domEl).on 'mousedown', (e) ->
    return if isLocked or $(e.target).closest('.cdt-ui, .lock-btn').length
    isDragging = true
    $(domEl).addClass('dragging')
    domEl.style.cursor = 'grabbing'
    startX = e.clientX - domEl.offsetLeft
    startY = e.clientY - domEl.offsetTop
    $(document).on 'mousemove', mouseMoveHandler
    $(document).on 'mouseup', mouseUpHandler

  mouseMoveHandler = (e) ->
    if isDragging
      newTop = (e.clientY - startY) + 'px'
      newLeft = (e.clientX - startX) + 'px'
      domEl.style.top = newTop
      domEl.style.left = newLeft
      $(domEl).find('#coords').text("T: #{newTop} L: #{newLeft}")

  mouseUpHandler = ->
    if isDragging
      isDragging = false
      $(domEl).removeClass('dragging')
      domEl.style.cursor = if isLocked then 'default' else 'grab'
      localStorage.setItem("#{P}_pos_top2", domEl.style.top)
      localStorage.setItem("#{P}_pos_left2", domEl.style.left)
      $(document).off 'mousemove', mouseMoveHandler
      $(document).off 'mouseup', mouseUpHandler

  CDT.init(domEl, P, @run?.bind(this), {info: {top: 10, right: 28}})

update: (output, domEl) ->
  try
    d = JSON.parse(output)
  catch e
    return
  $(domEl).find('#wifi-ico').text(String.fromCharCode(0xE9C9))
  $(domEl).find('#ssid').text(d.ssid or "None")
  $(domEl).find('#down').text(d.down or "0 B")
  $(domEl).find('#up').text(d.up or "0 B")
  # storico sparkline TENUTO SUL domEl (per-istanza) → sicuro con multi-monitor
  push = (k, v) ->
    v = 0 unless typeof v is 'number' and isFinite(v) and v >= 0
    a = (domEl[k] or []).concat([v])
    domEl[k] = a.slice(-40)
    domEl[k]
  dh = push('_cdDH', d.dbytes)
  uh = push('_cdUH', d.ubytes)
  spark = (arr) ->
    arr = [0] unless arr and arr.length
    w = 107; h = 24; bw = w / 40
    max = Math.max.apply(null, arr.concat([1]))
    bars = arr.map((v, i) ->
      bh = Math.max(0, Math.min(h, (v / max) * h))
      "<rect x='#{(i*bw).toFixed(1)}' y='#{(h-bh).toFixed(1)}' width='#{(bw*0.8).toFixed(1)}' height='#{bh.toFixed(1)}' style='fill:var(--cd-bright, #AED6F1)'></rect>"
    ).join('')
    "<svg width='#{w}' height='#{h}' style='display:block'><rect width='#{w}' height='#{h}' style='fill:var(--cd-shadow, #1F3A5F)' fill-opacity='0.35'></rect>#{bars}</svg>"
  domEl.querySelector('#dspark').innerHTML = spark(dh)
  domEl.querySelector('#uspark').innerHTML = spark(uh)
