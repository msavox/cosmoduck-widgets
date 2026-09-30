# Cosmoduck · Tutto in uno — Übersicht (legacy, lockable & draggable)
#
# Una card sola con meteo, sistema, sensori, rete, processi e uso di Claude:
# gli stessi dati delle card separate, per chi preferisce un blocco unico
# invece di una colonna. Orologio e calendario restano fuori: sono un'altra
# cosa, e su quelli la colonna funziona meglio.
#
# I dati arrivano da scripts/collect.sh, che richiama i collector dei singoli
# widget in parallelo: la logica di raccolta resta scritta una volta sola.

# Rimettere la card dove l'hai lasciata, prima che si veda altrove.
#
# Nota sui limiti: il default qui sotto e' l'angolo in alto a sinistra, come le
# altre card del set. Non e' un dettaglio estetico -- e' il posto in cui la card
# si vede per la prima frazione di secondo, prima che qualcuno possa spostarla,
# e piu' e' vicino a dove la tieni meno si nota.
#
# Lo style qui sotto e' statico: lo compila il server con Stylus e non sa niente
# di dove hai trascinato la card, che vive nel localStorage del browser. E
# afterRender -- dove la posizione viene ripristinata -- Ubersicht lo chiama
# solo quando il comando ritorna, che per questo pannello e' un secondo dopo:
# in quel secondo la card sta alla posizione di default, e si vede.
#
# Questo blocco invece gira nel browser appena la pagina carica il modulo, cioe'
# prima che il comando parta. L'elemento magari non c'e' ancora, quindi lo si
# aspetta a piccoli passi per un secondo scarso. Si scrive sullo stile inline,
# non in un foglio: cosi' il trascinamento, che scrive negli stessi campi,
# continua a funzionare.
do ->
  try
    savedTop = localStorage.getItem('cosmoduck-all_pos_top2')
    savedLeft = localStorage.getItem('cosmoduck-all_pos_left2')
    return unless savedTop and savedLeft
    tries = 0
    place = ->
      el = document.querySelector('[id^="cosmoduck-all-widget"]')
      if el
        el.style.top = savedTop
        el.style.left = savedLeft
        return
      tries += 1
      setTimeout(place, 25) if tries < 40
    place()
  catch error
    # Nessun browser: e' il server che sta leggendo il file, e li' non c'e'
    # niente da posizionare.
    return

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

command: "bash cosmoduck-all.widget/scripts/collect.sh"
refreshFrequency: 5000

style: """
  top: 18px
  left: 12px
  width: 214.2px
  height: 884px
  box-sizing: border-box
  overflow: hidden
  color: var(--cd-text, #C8D9E8)
  font-family: 'CDAbel', -apple-system, sans-serif
  background: var(--cd-glass, rgba(16,24,34,0.55))
  -webkit-backdrop-filter: blur(12px) saturate(1.2)
  backdrop-filter: blur(12px) saturate(1.2)
  border-radius: 24.2px
  border: 1px solid var(--cd-border, rgba(93,173,226,0.22))
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.07)
  padding: 13.2px 15.4px
  display: flex
  flex-direction: column
  justify-content: center
  user-select: none
  pointer-events: auto
  cursor: grab

  // La card e' una colonna flex, e un figlio flex per difetto si lascia
  // comprimere: quando il contenuto sfiora l'altezza, le righe dei processi si
  // schiacciavano l'una sull'altra invece di restare intere. Qui nessuno si
  // stringe -- se proprio non ci sta, meglio che si veda.
  > *
    flex: 0 0 auto

  &.locked
    cursor: default

  .lock-btn
    position: absolute
    top: 11px
    right: 9.9px
    color: var(--cd-bright, #AED6F1)
    width: 16.5px
    height: 16.5px
    opacity: 0
    cursor: pointer
    transition: opacity 0.2s
    z-index: 10
  &:hover .lock-btn
    opacity: 0.55
  .lock-btn:hover
    opacity: 1
  .lock-btn svg
    width: 16.5px
    height: 16.5px
    display: block

  .pos-indicator
    position: absolute
    bottom: 2.2px
    left: 50%
    transform: translateX(-50%)
    background: rgba(0,0,0,0.6)
    color: #fff
    font-size: 8.8px
    padding: 2.2px 8.8px
    border-radius: 11px
    opacity: 0
    transition: opacity 0.3s
    pointer-events: none
    z-index: 10
  .dragging .pos-indicator
    opacity: 1

  .sec
    display: flex
    align-items: baseline
    justify-content: space-between
    font-size: 10.5px
    letter-spacing: 1.5px
    opacity: 0.45
    margin-bottom: 4.4px
  .sec .st
    letter-spacing: 0.6px
  .sec2
    margin-top: 6.6px
  .rule
    height: 1px
    margin: 6.6px 0
    background: var(--cd-rule, rgba(93,173,226,0.14))
  .gly
    font-family: 'CDFeather'
    color: var(--cd-mid, #85C1E9)

  // Il meteo di adesso sta su una griglia di due righe e tre colonne, non su
  // due righe indipendenti: la prima colonna tiene temperatura e vento, la
  // seconda le estreme di oggi e l'umidita'. Cosi' l'umidita' cade sotto i due
  // numeri della giornata invece di finire a meta' strada, e le due colonne si
  // allargano insieme al testo piu' largo che contengono. La terza -- lo spazio
  // che restava vuoto a destra -- e' il nome della citta'.
  .wx
    display: grid
    grid-template-columns: auto auto 1fr
    column-gap: 13.2px
    row-gap: 3.3px
    align-items: center
    margin-bottom: 4.4px
  .wx .now
    grid-column: 1
    grid-row: 1
    display: flex
    align-items: baseline
    gap: 8.8px
  .wx .ico
    font-family: 'CDFeather'
    font-size: 24.2px
    line-height: 1
    color: var(--cd-text, #C8D9E8)
    transform: translateY(2.2px)
  .wx .t
    font-family: 'CDBebas', sans-serif
    font-size: 28.6px
    line-height: 1
    color: var(--cd-accent, #5DADE2)
  // Massima e minima di oggi: centrate sul blocco della temperatura invece di
  // appoggiarsi alla sua linea di base, che le faceva pendere in basso. La
  // freccia sta in una colonnina di larghezza fissa, cosi' i due numeri si
  // incolonnano invece di ballare a seconda della freccia.
  .wx .mm
    grid-column: 2
    grid-row: 1
    font-size: 12.1px
    line-height: 1.3
    opacity: 0.75
  .wx .mm .g
    font-family: 'CDFeather'
    display: inline-block
    width: 13.2px
    font-size: 9.9px
    opacity: 0.7
  // Come nella card meteo da sola: non la scritta piccola e spaziata
  // dell'intestazione, ma il nome scritto per esteso, nel colore d'accento.
  .wx .city
    grid-column: 3
    grid-row: 1 / span 2
    align-self: start
    text-align: left
    font-size: 15.4px
    line-height: 1.2
    font-weight: 700
    color: var(--cd-accent, #5DADE2)
    overflow: hidden
    text-overflow: ellipsis
    white-space: nowrap
  .wx .wind
    grid-column: 1
    grid-row: 2
  .wx .hum
    grid-column: 2
    grid-row: 2
  .wx .wind, .wx .hum
    font-size: 11px
    opacity: 0.85
  .wx .wind .gly, .wx .hum .gly
    font-size: 11px
    display: inline-block
    width: 13.2px
  .fc
    display: grid
    grid-template-columns: repeat(5, 1fr)
    text-align: center
    max-width: 100%
  .fc .d
    font-size: 9.9px
    opacity: 0.5
  // La striscia occupa tutta la larghezza della card, e a 183 punti ogni giorno
  // ne ha piu' di 36: icone e temperature possono permettersi di crescere.
  .fc .i
    font-family: 'CDFeather'
    font-size: 18.7px
    line-height: 1.45
    color: var(--cd-mid, #85C1E9)
  .fc .hi
    font-size: 11px
    line-height: 1.25
    color: var(--cd-accent, #5DADE2)
  .fc .lo
    font-size: 11px
    line-height: 1.25
    opacity: 0.45
  .mix
    position: relative
    display: inline-block
    width: 1em
    height: 1em
    vertical-align: -0.12em
  .mix .s
    position: absolute
    left: -0.16em
    top: -0.30em
    font-size: 0.72em
    opacity: 0.9
  .mix .c
    position: absolute
    right: -0.16em
    bottom: -0.16em
    font-size: 0.88em

  .rings
    display: block
    width: 100%
    height: 55px
  .rings circle
    fill: none
    stroke-width: 4
    stroke-linecap: round
  .rings .bg
    opacity: 0.22
  .r-cpu
    stroke: var(--cd-accent, #5DADE2)
  .r-mem
    stroke: var(--cd-mid, #85C1E9)
  .r-disk
    stroke: var(--cd-deep, #2874A6)
  // La percentuale sta dentro il suo anello: e' il numero che l'anello
  // disegna, e tenerlo altrove obbligava a rileggere due volte.
  .rings .pct
    font-family: 'CDAbel', sans-serif
    font-size: 12px
    font-weight: 700
    fill: var(--cd-accent, #5DADE2)
    text-anchor: middle
  .syslabels
    display: grid
    grid-template-columns: repeat(3, 1fr)
    text-align: center
    margin-top: 4.4px
  .syslabels .k
    font-size: 9.4px
    letter-spacing: 1px
    opacity: 0.5
  .syslabels .v
    font-size: 11.6px
    line-height: 1.3
    color: var(--cd-mid, #85C1E9)

  .grid2
    display: grid
    grid-template-columns: 1fr 1fr
    column-gap: 13.2px
  .trow
    display: flex
    align-items: baseline
    gap: 6.6px
    margin-bottom: 4.4px
  .trow .k
    width: 24.2px
    flex: 0 0 auto
    font-size: 9.9px
    letter-spacing: 0.6px
    opacity: 0.6
  .trow .bar
    flex: 1 1 auto
    align-self: center
    height: 4.4px
    border-radius: 2.2px
    background: var(--cd-track, rgba(31,58,95,0.55))
    overflow: hidden
  .trow .bar i
    display: block
    height: 100%
    width: 0
    border-radius: 2.2px
    background: var(--cd-accent, #5DADE2)
    transition: width 0.45s ease-out, background-color 0.45s
  .trow.hot .bar i
    background: var(--cd-bright, #AED6F1)
  .trow .v
    width: 44px
    flex: 0 0 auto
    text-align: right
    font-size: 11.6px
    color: var(--cd-accent, #5DADE2)
  .pw
    display: grid
    grid-template-columns: repeat(3, 1fr)
  .pw .l
    font-size: 8.8px
    letter-spacing: 0.8px
    opacity: 0.45
  .pw .n
    font-size: 11.6px
    line-height: 1.25
    color: var(--cd-mid, #85C1E9)

  .netrow
    display: flex
    align-items: center
    gap: 8.8px
    margin-bottom: 2.2px
  .netrow .k
    width: 72.6px
    flex: 0 0 auto
    font-size: 11.6px
  .netrow .k .gly
    font-size: 9.9px
    margin-right: 4.4px
  .netrow .sp
    flex: 1 1 auto
    height: 16.5px
  .netrow .sp svg
    width: 100%
    height: 16.5px
    display: block
  .netrow .sp polyline
    fill: none
    stroke: var(--cd-accent, #5DADE2)
    stroke-width: 1
    stroke-linejoin: round
    opacity: 0.8
  .netrow .sp polygon
    fill: var(--cd-fill, rgba(93,173,226,0.18))
    stroke: none

  .prow
    position: relative
    display: flex
    align-items: baseline
    justify-content: space-between
    font-size: 11px
    line-height: 1.4
    padding: 0 5.5px
    border-radius: 3.3px
    overflow: hidden
  .prow .fill
    position: absolute
    top: 0
    bottom: 0
    left: 0
    width: 0
    border-radius: 3.3px
    background: var(--cd-fill, rgba(93,173,226,0.18))
    transition: width 0.4s ease-out
  .prow .n
    position: relative
    overflow: hidden
    white-space: nowrap
    text-overflow: ellipsis
    padding-right: 6.6px
  .prow .p
    position: relative
    flex: 0 0 auto
    color: var(--cd-accent, #5DADE2)

  // Le due quote stanno una per riga, come i sensori: affiancate su una riga
  // sola restavano due barrette da trenta punti e dei numeri da nove, che a
  // schermo non si leggevano. Qui la barra prende tutta la larghezza e il
  // numero ha la stessa taglia degli altri valori della card.
  .cc
    display: flex
    flex-direction: column
    gap: 5.5px
  .cc .q
    display: flex
    align-items: center
    gap: 6.6px
  .cc .q b
    width: 33px
    flex: 0 0 auto
    font-weight: 400
    font-size: 9.9px
    letter-spacing: 0.6px
    opacity: 0.6
  // L'orario del reset sta sopra la barra, dentro la riga, e non su una riga
  // sua: la card ha l'altezza fissa e avanzano una decina di punti, mentre due
  // righe in piu' ne vogliono una ventina. Cosi' la riga cresce di mezzo punto
  // e la barra tiene tutta la larghezza.
  .cc .tr
    flex: 1 1 auto
    display: flex
    flex-direction: column
    gap: 2.2px
  .cc .rs
    font-size: 8.8px
    line-height: 1
    letter-spacing: 0.4px
    text-align: right
    opacity: 0.6
  .cc .mini
    flex: 0 0 auto
    height: 6.6px
    border-radius: 3.3px
    background: var(--cd-track, rgba(31,58,95,0.55))
    overflow: hidden
  .cc .mini i
    display: block
    height: 100%
    width: 0
    border-radius: 3.3px
    background: var(--cd-accent, #5DADE2)
    transition: width 0.45s ease-out
  .cc .v
    width: 44px
    flex: 0 0 auto
    text-align: right
    font-size: 13.2px
    color: var(--cd-accent, #5DADE2)

  .cal-hdr
    display: flex
    align-items: center
    font-size: 13.2px
    font-weight: 700
    color: var(--cd-accent, #5DADE2)
    margin-bottom: 6.6px
  .cal-hdr .mo
    overflow: hidden
    white-space: nowrap
    text-overflow: ellipsis
  .cal-hdr .td
    flex: 0 0 auto
    margin-left: auto
    padding: 0 4.4px
    font-size: 9.9px
    font-weight: 400
    letter-spacing: 0.4px
    color: var(--cd-bright, #AED6F1)
    opacity: 0.6
    border-radius: 4.4px
  .cal-hdr .td.btn
    cursor: pointer
    opacity: 0.85
  .cal-hdr .td.btn:hover
    opacity: 1
    background: var(--cd-fill, rgba(93,173,226,0.18))
  .cal-hdr .nav
    flex: 0 0 auto
    width: 15.4px
    text-align: center
    font-size: 16.5px
    line-height: 16.5px
    color: var(--cd-bright, #AED6F1)
    opacity: 0.45
    border-radius: 4.4px
    cursor: pointer
    transition: opacity 0.15s, background 0.15s
  .cal-hdr .nav:hover
    opacity: 1
    background: var(--cd-fill, rgba(93,173,226,0.18))
  .grid
    display: grid
    grid-template-columns: 18.7px repeat(7, 1fr)
    row-gap: 1px
  .dow
    font-size: 8.8px
    letter-spacing: 0.4px
    text-align: center
    color: var(--cd-bright, #AED6F1)
    opacity: 0.5
    padding-bottom: 3.3px
    border-bottom: 1px solid var(--cd-rule, rgba(93,173,226,0.14))
    margin-bottom: 3.3px
  .cw
    height: 20.9px
    line-height: 20.9px
    text-align: center
    font-size: 9.4px
    color: var(--cd-bright, #AED6F1)
    opacity: 0.3
    border-right: 1px solid var(--cd-rule-faint, rgba(93,173,226,0.12))
  .dow.cw
    height: auto
    line-height: normal
    opacity: 0.3
  .cell
    height: 20.9px
    line-height: 20.9px
    text-align: center
    font-size: 11.6px
    border-radius: 5.5px
    cursor: pointer
    transition: background 0.15s
  .cell.we
    color: var(--cd-mid, #85C1E9)
  .cell.out
    opacity: 0.22
  .cell:hover
    background: var(--cd-fill, rgba(93,173,226,0.18))
  .cell.today
    background: var(--cd-accent, #5DADE2)
    color: var(--cd-ink, #0F1722)
    font-weight: 700
  .cell.today:hover
    background: var(--cd-mid, #85C1E9)
"""

render: -> """
  <style>
    @font-face{font-family:'CDAbel';src:url('cosmoduck-all.widget/fonts/Abel-Regular.ttf') format('truetype');}
    @font-face{font-family:'CDBebas';src:url('cosmoduck-all.widget/fonts/BebasNeue-Regular.ttf') format('truetype');}
    @font-face{font-family:'CDFeather';src:url('cosmoduck-all.widget/fonts/feather.ttf') format('truetype');}
  </style>
  <div class="lock-btn" id="lock-toggle"></div>

  <div class="sec"><span>WEATHER</span></div>
  <div class="wx">
    <div class="now">
      <span class="ico" id="a-wicon"></span>
      <span class="t" id="a-wtemp">--°</span>
    </div>
    <div class="mm">
      <div><span class="g" id="a-gmax"></span><span id="a-wmax">--</span></div>
      <div><span class="g" id="a-gmin"></span><span id="a-wmin">--</span></div>
    </div>
    <div class="city" id="a-city">—</div>
    <div class="wind"><span class="gly" id="a-gwind"></span><span id="a-wind">--</span></div>
    <div class="hum"><span class="gly" id="a-ghum"></span><span id="a-hum">--</span></div>
  </div>
  <div class="fc" id="a-fc"></div>

  <div class="rule"></div>
  <div class="sec"><span>SYSTEM</span><span class="st">FREE</span></div>
  <svg class="rings" viewBox="0 0 186 50">
    <circle class="bg r-cpu"  cx="31" cy="25" r="20"></circle>
    <circle class="fg r-cpu"  id="a-ring-cpu"  cx="31" cy="25" r="20" stroke-dasharray="0 125.66" transform="rotate(-90 31 25)"></circle>
    <text class="pct" x="31" y="29" id="a-pcpu">--</text>
    <circle class="bg r-mem"  cx="93" cy="25" r="20"></circle>
    <circle class="fg r-mem"  id="a-ring-mem"  cx="93" cy="25" r="20" stroke-dasharray="0 125.66" transform="rotate(-90 93 25)"></circle>
    <text class="pct" x="93" y="29" id="a-pmem">--</text>
    <circle class="bg r-disk" cx="155" cy="25" r="20"></circle>
    <circle class="fg r-disk" id="a-ring-disk" cx="155" cy="25" r="20" stroke-dasharray="0 125.66" transform="rotate(-90 155 25)"></circle>
    <text class="pct" x="155" y="29" id="a-pdisk">--</text>
  </svg>
  <div class="syslabels">
    <div><div class="k">CPU</div><div class="v">&nbsp;</div></div>
    <div><div class="k">RAM</div><div class="v" id="a-ramfree">--</div></div>
    <div><div class="k">DISK</div><div class="v" id="a-diskfree">--</div></div>
  </div>

  <div class="rule"></div>
  <div class="sec"><span>SENSORS</span><span class="st" id="a-battst"></span></div>
  <div class="trow" id="a-row-cpu"><span class="k">CPU</span><span class="bar"><i id="a-bar-cpu"></i></span><span class="v" id="a-cputemp">--</span></div>
  <div class="trow" id="a-row-gpu"><span class="k">GPU</span><span class="bar"><i id="a-bar-gpu"></i></span><span class="v" id="a-gputemp">--</span></div>
  <div class="trow" id="a-row-bat"><span class="k">BAT</span><span class="bar"><i id="a-bar-bat"></i></span><span class="v" id="a-battpct">--</span></div>
  <div class="pw">
    <div><div class="l">CPU W</div><div class="n" id="a-cpupwr">--</div></div>
    <div><div class="l">GPU W</div><div class="n" id="a-gpupwr">--</div></div>
    <div><div class="l">SYS W</div><div class="n" id="a-syspwr">--</div></div>
  </div>

  <div class="rule"></div>
  <div class="sec"><span>NETWORK</span><span class="st" id="a-ssid">—</span></div>
  <div class="netrow"><span class="k"><span class="gly" id="a-gdown"></span><span id="a-down">--</span></span><span class="sp" id="a-spdown"></span></div>
  <div class="netrow"><span class="k"><span class="gly" id="a-gup"></span><span id="a-up">--</span></span><span class="sp" id="a-spup"></span></div>

  <div class="rule"></div>
  <div class="sec"><span>CPU</span><span class="st">%</span></div>
  <div class="prow"><span class="fill" id="a-cf0"></span><span class="n" id="a-cn0"></span><span class="p" id="a-cp0"></span></div>
  <div class="prow"><span class="fill" id="a-cf1"></span><span class="n" id="a-cn1"></span><span class="p" id="a-cp1"></span></div>
  <div class="prow"><span class="fill" id="a-cf2"></span><span class="n" id="a-cn2"></span><span class="p" id="a-cp2"></span></div>
  <div class="sec sec2"><span>MEMORY</span><span class="st">%</span></div>
  <div class="prow"><span class="fill" id="a-rf0"></span><span class="n" id="a-rn0"></span><span class="p" id="a-rp0"></span></div>
  <div class="prow"><span class="fill" id="a-rf1"></span><span class="n" id="a-rn1"></span><span class="p" id="a-rp1"></span></div>
  <div class="prow"><span class="fill" id="a-rf2"></span><span class="n" id="a-rn2"></span><span class="p" id="a-rp2"></span></div>

  <div class="rule"></div>
  <div class="sec"><span>CLAUDE</span><span class="st" id="a-ccmodel">—</span></div>
  <div class="cc">
    <span class="q"><b>SESS</b><span class="tr"><span class="rs" id="a-ccsrs">&nbsp;</span><span class="mini"><i id="a-ccsbar"></i></span></span><span class="v" id="a-ccs">--</span></span>
    <span class="q"><b>WEEK</b><span class="tr"><span class="rs" id="a-ccwrs">&nbsp;</span><span class="mini"><i id="a-ccwbar"></i></span></span><span class="v" id="a-ccw">--</span></span>
  </div>

  <div class="rule"></div>
  <div class="cal-hdr">
    <span class="mo" id="a-month">—</span>
    <span class="td" id="a-today"></span>
    <span class="nav" id="a-prev">&#8249;</span>
    <span class="nav" id="a-next">&#8250;</span>
  </div>
  <div class="grid" id="a-grid"></div>

  <div class="pos-indicator" id="coords">T: 0 L: 0</div>
"""
afterRender: (domEl) ->
  P = "cosmoduck-all"
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

  # ── calendario ──────────────────────────────────────────────────────────────
  # Stessa griglia della card dedicata: mese con oggi evidenziato, numero di
  # settimana ISO nella prima colonna, frecce per sfogliare e click su un giorno
  # per aprire Calendar su quella data. Il mese mostrato e' uno stato del widget
  # (offset in mesi) che il refresh ogni cinque secondi non deve azzerare.
  WEEK_START = 1
  MONTHS = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY',
            'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER']
  DOW = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA']
  offset = 0
  drawn = null
  pad = (n) -> if n < 10 then "0#{n}" else "#{n}"

  isoWeek = (date) ->
    thu = new Date(date.getFullYear(), date.getMonth(), date.getDate() + 3 - ((date.getDay() + 6) % 7))
    first = new Date(thu.getFullYear(), 0, 4)
    first.setDate(first.getDate() + 3 - ((first.getDay() + 6) % 7))
    1 + Math.round((thu - first) / 604800000)

  draw = (force) ->
    day = domEl.dataset.day
    return unless day
    key = "#{day}/#{offset}"
    return if drawn == key and not force
    drawn = key
    [y, m, d] = (parseInt(v, 10) for v in day.split('-'))
    view  = new Date(y, m - 1 + offset, 1)
    vy    = view.getFullYear()
    vm    = view.getMonth()
    lead  = (view.getDay() - WEEK_START + 7) % 7
    inMon = new Date(vy, vm + 1, 0).getDate()
    head = ["<div class='dow cw'>CW</div>"]
    head.push "<div class='dow'>#{DOW[(WEEK_START + i) % 7]}</div>" for i in [0...7]
    # Sempre 6 righe: l'altezza della card non deve ballare da un mese all'altro.
    cells = for i in [0...42]
      n    = i - lead + 1
      cell = new Date(vy, vm, n)
      cls  = ['cell']
      cls.push 'we' if ((WEEK_START + i % 7) % 7) in [0, 6]
      cls.push 'out' if n < 1 or n > inMon
      cls.push 'today' if cell.getFullYear() == y and cell.getMonth() == m - 1 and cell.getDate() == d
      iso = "#{cell.getFullYear()}-#{pad(cell.getMonth() + 1)}-#{pad(cell.getDate())}"
      # La riga porta il numero di settimana del proprio giovedi'.
      week = if i % 7 == 0
        thu = new Date(vy, vm, n + ((4 - WEEK_START + 7) % 7))
        "<div class='cw'>#{isoWeek(thu)}</div>"
      else
        ''
      week + "<div class='#{cls.join(' ')}' data-date='#{iso}'>#{cell.getDate()}</div>"
    $(domEl).find('#a-month').text("#{MONTHS[vm]} #{vy}")
    $(domEl).find('#a-today')
      .text(if offset == 0 then "#{DOW[new Date(y, m - 1, d).getDay()]} #{d}" else 'TODAY')
      .toggleClass('btn', offset != 0)
    $(domEl).find('#a-grid').html(head.join('') + cells.join(''))

  domEl.__draw = draw

  # `run` arriva da Übersicht sull'oggetto del widget (API legacy). Se un domani
  # sparisse, il click semplicemente non fa nulla invece di rompere il widget.
  shell = if typeof @run == 'function' then @run.bind(this) else null

  openCal = (iso) ->
    return unless shell and iso
    [y, m, d] = (parseInt(v, 10) for v in "#{iso}".split('-'))
    return if isNaN(y) or isNaN(m) or isNaN(d)
    # Il giorno si azzera PRIMA di cambiare mese: partendo dal 31 un mese piu'
    # corto traboccherebbe. Mezzogiorno per stare lontani dai salti d'ora legale.
    arg = (t) -> "-e '#{t}' "
    shell "osascript " +
      arg("set d to current date") + arg("set day of d to 1") +
      arg("set year of d to #{y}") + arg("set month of d to #{m}") +
      arg("set day of d to #{d}") + arg("set time of d to 12 * hours") +
      arg('tell application "Calendar" to activate') +
      arg('tell application "Calendar" to view calendar at d')

  isDragging = false
  hasMoved = false
  startX = 0
  startY = 0

  # Delegati: la griglia viene riscritta a ogni ridisegno, i suoi figli no.
  # `hasMoved` distingue il click dal trascinamento partito sopra una cella.
  $(domEl).on 'click', '#a-prev', (e) ->
    e.stopPropagation()
    return if hasMoved
    offset -= 1
    draw(true)

  $(domEl).on 'click', '#a-next', (e) ->
    e.stopPropagation()
    return if hasMoved
    offset += 1
    draw(true)

  $(domEl).on 'click', '#a-today', (e) ->
    e.stopPropagation()
    return if hasMoved or offset == 0
    offset = 0
    draw(true)

  $(domEl).on 'click', '.cell', (e) ->
    e.stopPropagation()
    return if hasMoved
    openCal($(e.currentTarget).attr('data-date'))

  $(domEl).on 'mousedown', (e) ->
    return if isLocked or $(e.target).closest('.cdt-ui, .lock-btn').length
    hasMoved = false
    isDragging = true
    $(domEl).addClass('dragging')
    domEl.style.cursor = 'grabbing'
    startX = e.clientX - domEl.offsetLeft
    startY = e.clientY - domEl.offsetTop
    $(document).on 'mousemove', mouseMoveHandler
    $(document).on 'mouseup', mouseUpHandler

  mouseMoveHandler = (e) ->
    if isDragging
      hasMoved = true
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

  CDT.init(domEl, P, @run?.bind(this), {info: {right: 9.9, bottom: 11, size: 16.5}})

update: (output, domEl) ->
  try
    d = JSON.parse(output)
  catch e
    return
  return unless d
  $el = $(domEl)
  num = (v, dec) -> if v? and not isNaN(v) then (+v).toFixed(dec) else 'n/d'
  # Codepoint nel font Feather in dotazione (vedi fonts/feather.ttf).
  ICONS =
    "01d": 0xE9E3, "01n": 0xE9A3
    "03d": 0xE93A, "03n": 0xE93A
    "04d": 0xE93A, "04n": 0xE93A
    "09d": 0xE93B, "09n": 0xE93B, "10d": 0xE93E, "10n": 0xE93E
    "11d": 0xE93C, "11n": 0xE93C, "13d": 0xE93F, "13n": 0xE93F
    "50d": 0xEA10, "50n": 0xEA10
  SUN = 0xE9E3; MOON = 0xE9A3; CLOUD = 0xE93A
  WIND = 0xEA10; DROP = 0xE95A; DOWN = 0xE90C; UP = 0xE914
  ch = (cp) -> String.fromCharCode(cp)
  # "02" e' poche nubi: ne' sereno ne' coperto, e Feather non ha un sole dietro
  # le nuvole. Si compone con i due glifi che ci sono.
  glyph = (code) ->
    if code is '02d' or code is '02n'
      back = if code is '02d' then SUN else MOON
      """<span class="mix"><span class="s">#{ch(back)}</span><span class="c">#{ch(CLOUD)}</span></span>"""
    else
      ch(ICONS[code] or CLOUD)

  # ── meteo ───────────────────────────────────────────────────────────────────
  wx = d.wx
  w = wx?.current
  if w?.main and w?.weather?[0]
    $el.find('#a-wicon').html(glyph(w.weather[0].icon))
    $el.find('#a-wtemp').text("#{Math.round(w.main.temp)}°")
    $el.find('#a-city').text(w.name or '—')
    $el.find('#a-gwind').text(ch(WIND))
    $el.find('#a-ghum').text(ch(DROP))
    $el.find('#a-wind').text("#{Math.round(w.wind.speed * 10) / 10} m/s")
    $el.find('#a-hum').text("#{w.main.humidity}%")
    today = wx.today or { min: Math.round(w.main.temp), max: Math.round(w.main.temp) }
    $el.find('#a-gmax').text(ch(UP))
    $el.find('#a-gmin').text(ch(DOWN))
    $el.find('#a-wmax').text("#{today.max}°")
    $el.find('#a-wmin').text("#{today.min}°")
    days = for day in (wx.forecast or [])
      """<div><div class="d">#{day.dow}</div><div class="i">#{glyph(day.icon)}</div>""" +
      """<div class="hi">#{day.max}°</div><div class="lo">#{day.min}°</div></div>"""
    $el.find('#a-fc').html(days.join(''))

  # ── sistema ────────────────────────────────────────────────────────────────
  sys = d.sys
  if sys
    ring = (id, pct) ->
      f = Math.max(0, Math.min(100, pct or 0)) / 100
      $el.find(id).attr('stroke-dasharray', "#{(f * 125.66).toFixed(2)} 125.66")
    ring('#a-ring-cpu', sys.cpu)
    ring('#a-ring-mem', sys.mem)
    ring('#a-ring-disk', sys.diskData)
    $el.find('#a-pcpu').text("#{sys.cpu}%")
    $el.find('#a-pmem').text("#{sys.mem}%")
    $el.find('#a-pdisk').text("#{sys.diskData}%")
    $el.find('#a-ramfree').text("#{sys.memFreeGB}GB")
    $el.find('#a-diskfree').text("#{sys.diskFreeGB}GB")

  # ── sensori e batteria ─────────────────────────────────────────────────────
  hw = d.hw
  if hw
    gauge = (bar, row, v, lo, hi, hot) ->
      if v? and not isNaN(v)
        pct = Math.max(0, Math.min(100, (v - lo) / (hi - lo) * 100))
        $el.find(bar).css('width', "#{pct.toFixed(1)}%")
        $el.find(row).toggleClass('hot', hot)
      else
        $el.find(bar).css('width', '0%')
    gauge('#a-bar-cpu', '#a-row-cpu', hw.cputemp, 30, 95, hw.cputemp >= 80)
    gauge('#a-bar-gpu', '#a-row-gpu', hw.gputemp, 30, 95, hw.gputemp >= 80)
    $el.find('#a-cputemp').text(if hw.cputemp? then "#{num(hw.cputemp, 1)}°" else 'n/d')
    $el.find('#a-gputemp').text(if hw.gputemp? then "#{num(hw.gputemp, 1)}°" else 'n/d')
    # Su parecchi Mac Apple Silicon macmon non riceve il canale della CPU e
    # riporta zero fisso: uno zero li' si legge come una misura, quindi quando
    # il sistema consuma e il canale no, si dice n/d.
    dead = (v) -> (not v?) or (v is 0 and hw.syspwr? and hw.syspwr > 1)
    $el.find('#a-cpupwr').text(if dead(hw.cpupwr) then 'n/d' else num(hw.cpupwr, 2))
    $el.find('#a-gpupwr').text(if dead(hw.gpupwr) then 'n/d' else num(hw.gpupwr, 2))
    $el.find('#a-syspwr').text(num(hw.syspwr, 2))
    b = hw.batt
    if b?.pct?
      gauge('#a-bar-bat', '#a-row-bat', b.pct, 0, 100, b.pct <= 20 and b.state isnt 'charging')
      $el.find('#a-battpct').text("#{b.pct}%")
      hhmm = if b.mins? then "#{Math.floor(b.mins / 60)}H#{String(b.mins % 60).padStart(2, '0')}" else null
      $el.find('#a-battst').text(
        switch b.state
          when 'charging'    then (if hhmm then "TO FULL #{hhmm}" else 'CHARGING')
          when 'discharging' then (if hhmm then "#{hhmm} LEFT" else 'ON BATTERY')
          when 'charged', 'finishing charge' then 'FULL'
          else (if b.ac then 'AC' else (hhmm or '')))

  # ── rete ───────────────────────────────────────────────────────────────────
  net = d.net
  if net
    $el.find('#a-ssid').text((net.ssid or '').toUpperCase())
    $el.find('#a-gdown').text(ch(DOWN))
    $el.find('#a-gup').text(ch(UP))
    $el.find('#a-down').text(net.down or '--')
    $el.find('#a-up').text(net.up or '--')
    # Lo storico sta appeso all'elemento e non in una variabile di modulo: un
    # assegnamento nudo fra due chiavi chiuderebbe l'object literal del widget,
    # e Ubersicht si ritroverebbe una card senza command ne' render.
    MAX = 40
    trace = (key, sel, v) ->
      hist = $el.data(key) or []
      hist.push(Math.max(0, +v or 0))
      hist.shift() while hist.length > MAX
      $el.data(key, hist)
      return if hist.length < 2
      W = 100; H = 15
      top = Math.max(1, Math.max(hist...))
      step = W / (MAX - 1)
      pts = (for y, i in hist
        x = (i + MAX - hist.length) * step
        "#{x.toFixed(1)},#{(H - 1 - (y / top) * (H - 2)).toFixed(1)}").join(' ')
      first = pts.split(' ')[0].split(',')[0]
      last = pts.split(' ')[hist.length - 1].split(',')[0]
      $el.find(sel).html("""<svg viewBox="0 0 #{W} #{H}" preserveAspectRatio="none">
        <polygon points="#{first},#{H} #{pts} #{last},#{H}"></polygon>
        <polyline points="#{pts}"></polyline></svg>""")
    trace('dhist', '#a-spdown', net.dbytes)
    trace('uhist', '#a-spup', net.ubytes)

  # ── processi ───────────────────────────────────────────────────────────────
  pr = d.proc
  if pr
    # La barra dietro ogni riga e' relativa al primo della lista: pcpu su otto
    # core arriva a 800, e la domanda qui e' chi sta mangiando la macchina.
    fill = (arr, pfx, floor) ->
      top = Math.max(floor, Math.max(0, (parseFloat(p.p) or 0 for p in arr)...))
      for i in [0..2]
        p = arr[i]
        v = if p then (parseFloat(p.p) or 0) else 0
        $el.find("##{pfx}n#{i}").text(if p then p.n else '')
        $el.find("##{pfx}p#{i}").text(if p then p.p else '')
        $el.find("##{pfx}f#{i}").css('width', if p then "#{(v / top * 100).toFixed(1)}%" else '0')
    fill((pr.topcpu or []), 'a-c', 25)
    fill((pr.topram or []), 'a-r', 8)

  # ── calendario ─────────────────────────────────────────────────────────────
  if /^\d{4}-\d{2}-\d{2}$/.test(d.day or '')
    domEl.dataset.day = d.day
    domEl.__draw?()

  # ── Claude ─────────────────────────────────────────────────────────────────
  cc = d.cc
  if cc
    $el.find('#a-ccmodel').text((cc.model or '').toUpperCase())
    for [q, bar, val] in [[cc.session, '#a-ccsbar', '#a-ccs'], [cc.week, '#a-ccwbar', '#a-ccw']]
      continue unless q
      $el.find(bar).css('width', "#{Math.max(0, Math.min(100, q.pct or 0))}%")
      $el.find(val).text("#{q.pct}%")
    # Il prossimo reset, come nel widget dedicato: un'ora per la sessione,
    # giorno e ora per la settimana. La finestra di sessione nasce col primo
    # messaggio, quindi a Claude fermo non c'e' un orario da dire: IDLE.
    s = cc.session
    $el.find('#a-ccsrs').text(
      if not s then '' else if s.active then "\u21BB #{s.reset}" else 'IDLE')
    $el.find('#a-ccwrs').text(if cc.week?.reset then "\u21BB #{cc.week.reset.toUpperCase()}" else '')
  return
