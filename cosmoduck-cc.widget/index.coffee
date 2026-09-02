# Cosmoduck · Claude Code — Übersicht (legacy, lockable & draggable)
# Modello in uso + token della finestra di sessione (5h) e di quella settimanale,
# con percentuale, barra di riempimento e orario del prossimo reset.

command: "bash cosmoduck-cc.widget/scripts/collect.sh"
refreshFrequency: 60000

style: """
  top: 748px
  left: 12px
  width: 150px
  height: 140px
  box-sizing: border-box
  overflow: hidden
  color: #C8D9E8
  font-family: 'CDAbel', -apple-system, sans-serif
  background: rgba(16,24,34,0.55)
  -webkit-backdrop-filter: blur(12px) saturate(1.2)
  backdrop-filter: blur(12px) saturate(1.2)
  border-radius: 22px
  border: 1px solid rgba(93,173,226,0.22)
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.07)
  padding: 13px 16px 0 18px
  user-select: none
  pointer-events: auto
  cursor: grab

  &.locked
    cursor: default

  .lock-btn
    position: absolute
    top: 10px
    right: 9px
    color: #AED6F1
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

  .hdr
    display: flex
    align-items: center
    font-size: 13px
    font-weight: 700
    color: #5DADE2
    margin-bottom: 7px
  .hdr svg
    width: 10px
    height: 10px
    margin-right: 4px
    flex: 0 0 auto
  .hdr .m
    overflow: hidden
    white-space: nowrap
    text-overflow: ellipsis
  .hdr .e
    flex: 0 0 auto
    margin-left: 5px
    font-size: 9px
    font-weight: 400
    letter-spacing: 0.3px
    text-transform: uppercase
    color: #AED6F1
    opacity: 0.6

  .grp
    margin-bottom: 6px
  .grp:last-of-type
    margin-bottom: 0
  .row
    display: flex
    align-items: baseline
    justify-content: space-between
    font-size: 11px
    line-height: 1.15
  .row .k
    color: #C8D9E8
    opacity: 0.9
  .row .p
    font-weight: 700
    color: #5DADE2
  .sub
    font-size: 9px
    opacity: 0.62
  .sub .rs
    letter-spacing: 0.2px

  .last-hour
    display: flex
    justify-content: space-between
    align-items: baseline
    font-size: 10px
    margin-top: 7px
    padding-top: 5px
    border-top: 1px solid rgba(93,173,226,0.14)
  .last-hour .k
    opacity: 0.62
    font-size: 9px
    letter-spacing: 0.4px
  .last-hour .v
    color: #85C1E9
  .last-hour .age
    margin-left: 4px
    font-size: 8px
    letter-spacing: 0
    opacity: 0.9

  .bar
    height: 6px
    border-radius: 3px
    background: rgba(31,58,95,0.55)
    overflow: hidden
    margin: 2px 0
  .bar .fill
    height: 100%
    width: 0%
    border-radius: 3px
    background: #5DADE2
    transition: width 0.45s ease, background 0.45s ease
"""

render: -> """
  <style>@font-face{font-family:'CDAbel';src:url('cosmoduck-cc.widget/fonts/Abel-Regular.ttf') format('truetype');}</style>
  <div class="lock-btn" id="lock-toggle"></div>
  <div class="hdr">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon></svg>
    <span class="m" id="model">--</span><span class="e" id="effort"></span><span class="e" id="acct"></span>
  </div>

  <div class="grp">
    <div class="row"><span class="k">SESSION</span><span class="p" id="s-pct">--%</span></div>
    <div class="bar"><div class="fill" id="s-bar"></div></div>
    <div class="row sub"><span id="s-used">--</span><span class="rs">&#8635; <span id="s-reset">--:--</span></span></div>
  </div>

  <div class="grp">
    <div class="row"><span class="k">WEEK</span><span class="p" id="w-pct">--%</span></div>
    <div class="bar"><div class="fill" id="w-bar"></div></div>
    <div class="row sub"><span id="w-used">--</span><span class="rs">&#8635; <span id="w-reset">--</span></span></div>
  </div>

  <div class="last-hour">
    <span class="k">LAST HOUR<span class="age" id="age"></span></span><span class="v" id="h-used">--</span>
  </div>

  <div class="pos-indicator" id="coords">T: 0 L: 0</div>
"""

afterRender: (domEl) ->
  P = "cosmoduck-cc"
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
    return if isLocked or $(e.target).closest('.lock-btn').length
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

update: (output, domEl) ->
  try
    d = JSON.parse(output)
  catch e
    return

  if d.err
    $(domEl).find('#model').text(if d.err == 'nopython' then 'no python3' else 'error')
    return

  # oltre l'80% la barra vira verso l'ambra, oltre il 92% verso il rosso
  tone = (p) ->
    return '#EC7063' if p >= 92
    return '#E59866' if p >= 80
    '#5DADE2'

  fill = (id, pct) ->
    p = Math.max(0, Math.min(100, pct or 0))
    $(domEl).find("##{id}").css(width: "#{p}%", background: tone(p))

  $(domEl).find('#model').text(d.model or 'n/d')
  $(domEl).find('#effort').text(d.effort or '')

  # src: "live" quota reale aggiornata · "stale" quota reale ma vecchia · "est"
  # stima locale sui budget. Solo "live" e' un numero esatto e attuale, quindi
  # tutto il resto porta la "~".
  src = (o) -> o.src or (if o.live then 'live' else 'est')
  mark = (o) -> if src(o) == 'live' then '' else '~'

  # Quando la percentuale e' la quota reale il conteggio token viene dai transcript,
  # quindi NON e' il suo numeratore: si etichetta "local" per non leggerli insieme.
  used = (o) -> if src(o) == 'est' then (o.human or '0') else "local #{o.human or '0'}"

  s = d.session or {}
  fill('s-bar', s.pct)
  $(domEl).find('#s-pct').text("#{mark(s)}#{s.pct ? 0}%").css(color: tone(s.pct or 0))
  $(domEl).find('#s-used').text(used(s))
  $(domEl).find('#s-reset').text(if s.active then s.reset else 'idle')

  w = d.week or {}
  fill('w-bar', w.pct)
  $(domEl).find('#w-pct').text("#{mark(w)}#{w.pct ? 0}%").css(color: tone(w.pct or 0))
  $(domEl).find('#w-used').text(used(w))
  $(domEl).find('#w-reset').text(w.reset or '--')

  $(domEl).find('#h-used').text((d.hour or {}).human or '0')

  # Eta' del dato, accanto a LAST HOUR: quando la quota reale non e' piu' fresca
  # e' l'unica cosa che distingue "21% adesso" da "21% di tre ore fa". Con dato
  # live non si mostra nulla, cosi' la riga resta pulita nel caso normale.
  ago = (sec) ->
    return '' unless sec?
    return "#{Math.round(sec / 60)}m" if sec < 3600
    return "#{Math.round(sec / 3600)}h" if sec < 86400
    "#{Math.round(sec / 86400)}g"

  state = if src(s) == 'live' or src(w) == 'live' then 'live'
  else if src(s) == 'stale' or src(w) == 'stale' then 'stale'
  else 'est'

  [txt, col] = switch state
    when 'live'  then ['', '#C8D9E8']
    when 'stale' then ["~#{ago(d.age)}", '#E59866']
    else ['~stima', '#C8D9E8']

  $(domEl).find('#age').text(txt).css(color: col)

  # Etichetta manuale del login (ACCOUNT_LABEL): Claude Code non passa l'account
  # alla statusline, quindi il widget non puo' dedurlo — o lo dici tu, o niente.
  $(domEl).find('#acct').text(if d.label then "· #{d.label}" else '')
