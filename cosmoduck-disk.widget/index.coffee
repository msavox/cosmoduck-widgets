# Cosmoduck · Disco/Sistema — Übersicht (legacy, lockable & draggable)
# Box1.png (icone chip/CPU) + 4 ring SVG + System/Home %.

command: "bash cosmoduck-disk.widget/scripts/collect.sh"
refreshFrequency: 3000

style: """
  top: 18px
  left: 12px
  width: 150px
  height: 140px
  box-sizing: border-box
  overflow: hidden
  font-family: 'CDAbel', -apple-system, sans-serif
  color: var(--cd-text, #C8D9E8)
  background: url('cosmoduck-disk.widget/icons.png') no-repeat top left / 140px 140px, var(--cd-glass, rgba(16,24,34,0.55))
  -webkit-backdrop-filter: blur(12px) saturate(1.2)
  backdrop-filter: blur(12px) saturate(1.2)
  border-radius: 22px
  border: 1px solid var(--cd-border, rgba(93,173,226,0.22))
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.07)
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

  .rings
    position: absolute
    top: 0
    left: 0
  .bg
    fill: none
    stroke-opacity: 0.2
    stroke-width: 6
  .fg
    fill: none
    stroke-opacity: 0.85
    stroke-width: 6
  .txt
    position: absolute
    left: 73px
    top: 81px
  .txt .r
    display: flex
    align-items: baseline
    font-size: 13px
    line-height: 1.0
    font-weight: 700
    margin-bottom: 2px
  .txt .r .k
    width: 30px
    margin-right: -2px
    flex: 0 0 auto
    color: var(--cd-text, #C8D9E8)
    opacity: 0.9
  .txt .r .v
    color: var(--cd-accent, #5DADE2)

  // Il colore degli anelli vive qui e non nell'attributo stroke= perche' un
  // attributo di presentazione SVG non risolve var(). NB: qui dentro e' Stylus,
  // dove il commento e' //: un '#' diventerebbe un selettore, e basta un
  // selettore invalido nel gruppo perche' il browser butti tutta la regola.
  .r-cpu
    stroke: var(--cd-accent, #5DADE2)
  .r-mem
    stroke: var(--cd-mid, #85C1E9)
  .r-root
    stroke: var(--cd-deep, #2874A6)
  .r-data
    stroke: var(--cd-bright, #AED6F1)
"""

render: -> """
  <style>@font-face{font-family:'CDAbel';src:url('cosmoduck-disk.widget/fonts/Abel-Regular.ttf') format('truetype');}</style>
  <div class="lock-btn" id="lock-toggle"></div>
  <svg class="rings" width="150" height="140" viewBox="0 0 150 140">
    <circle class="bg r-cpu" cx="39.5" cy="39" r="22"></circle>
    <circle class="fg r-cpu" id="cpu-fg" cx="39.5" cy="39" r="22" stroke-dasharray="0 138.23" transform="rotate(-90 39.5 39)"></circle>
    <circle class="bg r-mem" cx="99.4" cy="39" r="22"></circle>
    <circle class="fg r-mem" id="mem-fg" cx="99.4" cy="39" r="22" stroke-dasharray="0 138.23" transform="rotate(-90 99.4 39)"></circle>
    <circle class="bg r-root" cx="41" cy="103" r="22"></circle>
    <circle class="fg r-root" id="root-fg" cx="41" cy="103" r="22" stroke-dasharray="0 138.23" transform="rotate(-90 41 103)"></circle>
    <circle class="bg r-data" cx="41" cy="103" r="13"></circle>
    <circle class="fg r-data" id="data-fg" cx="41" cy="103" r="13" stroke-dasharray="0 81.68" transform="rotate(-90 41 103)"></circle>
  </svg>
  <div class="txt">
    <div class="r"><span class="k">CPU</span><span class="v" id="v-cpu">--%</span></div>
    <div class="r"><span class="k">RAM</span><span class="v" id="v-ram">--GB</span></div>
    <div class="r"><span class="k">Disk</span><span class="v" id="v-disk">--GB</span></div>
  </div>
  <div class="pos-indicator" id="coords">T: 0 L: 0</div>
"""

afterRender: (domEl) ->
  P = "cosmoduck-disk"
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
  ring = (id, pct, circ) ->
    f = Math.max(0, Math.min(100, pct)) / 100
    $(domEl).find("##{id}").attr('stroke-dasharray', "#{(f*circ).toFixed(2)} #{circ}")
  ring('cpu-fg', d.cpu, 138.23)
  ring('mem-fg', d.mem, 138.23)
  ring('root-fg', d.diskRoot, 138.23)
  ring('data-fg', d.diskData, 81.68)
  $(domEl).find('#v-cpu').text("#{d.cpu}%")
  $(domEl).find('#v-ram').text("#{d.memFreeGB}GB")
  $(domEl).find('#v-disk').text("#{d.diskFreeGB}GB")
