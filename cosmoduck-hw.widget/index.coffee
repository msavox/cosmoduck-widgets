# Cosmoduck · Hardware Monitor — Übersicht (legacy, lockable & draggable)
# Sensori reali via macmon (sudoless): CPU/GPU die temp + power draw. brew install macmon

command: "bash cosmoduck-hw.widget/scripts/collect.sh"
refreshFrequency: 4000

style: """
  top: 602px
  left: 12px
  width: 150px
  height: 140px
  box-sizing: border-box
  overflow: hidden
  color: var(--cd-accent, #5DADE2)
  font-family: 'CDAbel', -apple-system, sans-serif
  background: var(--cd-glass, rgba(16,24,34,0.55))
  -webkit-backdrop-filter: blur(12px) saturate(1.2)
  backdrop-filter: blur(12px) saturate(1.2)
  border-radius: 22px
  border: 1px solid var(--cd-border, rgba(93,173,226,0.22))
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.07)
  padding: 8px 0 8px 20px
  display: flex
  flex-direction: column
  justify-content: center
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

  .sec
    display: flex
    align-items: baseline
    justify-content: space-between
    font-size: 8.5px
    letter-spacing: 1.4px
    color: var(--cd-text, #C8D9E8)
    opacity: 0.45
    margin: 0 18px 3px 0
  .sec .st
    letter-spacing: 0.5px
  .trow
    display: flex
    align-items: center
    gap: 7px
    margin-bottom: 3px
    padding-right: 18px
  .trow .k
    width: 26px
    flex: 0 0 auto
    font-size: 10px
    letter-spacing: 0.6px
    opacity: 0.6
  .trow .bar
    flex: 1 1 auto
    height: 4px
    border-radius: 2px
    background: var(--cd-track, rgba(31,58,95,0.55))
    overflow: hidden
  .trow .bar i
    display: block
    height: 100%
    width: 0
    border-radius: 2px
    background: var(--cd-accent, #5DADE2)
    transition: width 0.45s ease-out, background-color 0.45s
  .trow.hot .bar i
    background: var(--cd-bright, #AED6F1)
  .trow .v
    width: 40px
    flex: 0 0 auto
    text-align: right
    font-size: 11px
    color: var(--cd-accent, #5DADE2)
  .rule
    height: 1px
    margin: 1px 18px 4px 0
    background: var(--cd-rule, rgba(93,173,226,0.14))
  .pw
    position: relative
    display: grid
    grid-template-columns: repeat(3, 1fr)
    padding-right: 18px
  .pw .l
    font-size: 8px
    letter-spacing: 0.7px
    opacity: 0.45
  .pw .n
    font-size: 11px
    line-height: 1.2
    color: var(--cd-mid, #85C1E9)
  // Il tracciato degli ultimi due minuti sta dietro ai numeri invece di
  // occupare una fascia propria: la batteria vale piu' di sedici punti di
  // altezza, e cosi' la traccia resta senza costare niente.
  .spark
    position: absolute
    left: 0
    right: 18px
    bottom: -1px
    height: 22px
    opacity: 0.3
    pointer-events: none
  .spark svg
    width: 100%
    height: 22px
    display: block
  .spark polyline
    fill: none
    stroke: var(--cd-accent, #5DADE2)
    stroke-width: 1
    stroke-linejoin: round
    stroke-linecap: round
    opacity: 0.85
  .spark polygon
    fill: var(--cd-fill, rgba(93,173,226,0.18))
    stroke: none
"""

render: -> """
  <style>@font-face{font-family:'CDAbel';src:url('cosmoduck-hw.widget/fonts/Abel-Regular.ttf') format('truetype');}</style>
  <div class="lock-btn" id="lock-toggle"></div>
  <div class="sec"><span>TEMPERATURE</span><span class="st" id="hw-state"></span></div>
  <div class="trow" id="row-cpu"><span class="k">CPU</span><span class="bar"><i id="bar-cpu"></i></span><span class="v" id="hw-cputemp">--</span></div>
  <div class="trow" id="row-gpu"><span class="k">GPU</span><span class="bar"><i id="bar-gpu"></i></span><span class="v" id="hw-gputemp">--</span></div>
  <div class="rule"></div>
  <div class="sec"><span>BATTERY</span><span class="st" id="hw-battst">--</span></div>
  <div class="trow" id="row-bat"><span class="k">BAT</span><span class="bar"><i id="bar-bat"></i></span><span class="v" id="hw-battpct">--</span></div>
  <div class="rule"></div>
  <div class="sec"><span>POWER</span><span class="st">WATT</span></div>
  <div class="pw">
    <div class="spark" id="hw-spark"></div>
    <div><div class="l">CPU</div><div class="n" id="hw-cpupwr">--</div></div>
    <div><div class="l">GPU</div><div class="n" id="hw-gpupwr">--</div></div>
    <div><div class="l">SYS</div><div class="n" id="hw-syspwr">--</div></div>
  </div>
  <div class="pos-indicator" id="coords">T: 0 L: 0</div>
"""

afterRender: (domEl) ->
  P = "cosmoduck-hw"
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
  fmt = (v, dec) ->
    if v? and not isNaN(v) then (+v).toFixed(dec) else "n/d"

  # La batteria non dipende da macmon, quindi si aggiorna comunque.
  b = d.batt
  if b and b.pct?
    $(domEl).find('#bar-bat').css('width', "#{Math.max(0, Math.min(100, b.pct))}%")
    $(domEl).find('#hw-battpct').text("#{b.pct}%")
    # Sotto il 20% la barra passa al tono chiaro, come le temperature sopra gli 80.
    $(domEl).find('#row-bat').toggleClass('hot', b.pct <= 20 and b.state isnt 'charging')
    hhmm = if b.mins? then "#{Math.floor(b.mins / 60)}H#{String(b.mins % 60).padStart(2, '0')}" else null
    status = switch b.state
      when 'charging'    then (if hhmm then "TO FULL #{hhmm}" else 'CHARGING')
      when 'discharging' then (if hhmm then "#{hhmm} LEFT" else 'ON BATTERY')
      when 'charged', 'finishing charge' then 'FULL'
      else (if b.ac then 'AC' else (hhmm or ''))
    $(domEl).find('#hw-battst').text(status)
  else
    $(domEl).find('#hw-battpct').text('n/d')
    $(domEl).find('#hw-battst').text('')
    $(domEl).find('#bar-bat').css('width', '0%')

  if d.nomacmon
    $(domEl).find('#hw-state').text('macmon assente')
    $(domEl).find('#hw-cputemp,#hw-gputemp').text('n/d')
    $(domEl).find('#hw-cpupwr,#hw-gpupwr,#hw-syspwr').text('n/d')
    $(domEl).find('#bar-cpu,#bar-gpu').css('width', '0%')
    return
  $(domEl).find('#hw-state').text('')

  # Le temperature sono grandezze limitate, e una barra le racconta meglio di un
  # numero: 30 gradi e' un portatile fermo, 95 e' il punto in cui rallenta.
  gauge = (sel, row, v) ->
    if v? and not isNaN(v)
      pct = Math.max(0, Math.min(100, (v - 30) / 65 * 100))
      $(domEl).find(sel).css('width', "#{pct.toFixed(1)}%")
      $(domEl).find(row).toggleClass('hot', v >= 80)
    else
      $(domEl).find(sel).css('width', '0%')

  gauge('#bar-cpu', '#row-cpu', d.cputemp)
  gauge('#bar-gpu', '#row-gpu', d.gputemp)
  $(domEl).find('#hw-cputemp').text(if d.cputemp? then "#{fmt(d.cputemp, 1)}°" else 'n/d')
  $(domEl).find('#hw-gputemp').text(if d.gputemp? then "#{fmt(d.gputemp, 1)}°" else 'n/d')
  $(domEl).find('#hw-cpupwr').text(fmt(d.cpupwr, 2))
  $(domEl).find('#hw-gpupwr').text(fmt(d.gpupwr, 2))
  $(domEl).find('#hw-syspwr').text(fmt(d.syspwr, 2))

  return unless d.syspwr? and not isNaN(d.syspwr)
  # Lo storico sta appeso all'elemento e non in una variabile di modulo: il file
  # del widget e' un unico object literal, e un'assegnazione nuda in mezzo lo
  # chiuderebbe li' -- Ubersicht si ritroverebbe un widget senza command ne'
  # render, cioe' un riquadro vuoto. Appeso all'elemento e' anche piu' corretto:
  # Ubersicht monta un'istanza per schermo.
  HISTORY_MAX = 30
  hist = $(domEl).data('syshist') or []
  hist.push(+d.syspwr)
  hist.shift() while hist.length > HISTORY_MAX
  $(domEl).data('syshist', hist)
  return if hist.length < 2
  # Scala sul massimo visto nella finestra, con un minimo di 5 W: senza, il
  # rumore di una macchina ferma riempirebbe tutta l'altezza.
  W = 100
  H = 20
  top = Math.max(5, Math.max(hist...))
  step = W / (HISTORY_MAX - 1)
  pts = (for v, i in hist
    x = (i + HISTORY_MAX - hist.length) * step
    y = H - 1 - (v / top) * (H - 2)
    "#{x.toFixed(1)},#{y.toFixed(1)}").join(' ')
  svg = """<svg viewBox="0 0 #{W} #{H}" preserveAspectRatio="none">
      <polyline points="#{pts}"></polyline>
    </svg>"""
  $(domEl).find('#hw-spark').html(svg)
