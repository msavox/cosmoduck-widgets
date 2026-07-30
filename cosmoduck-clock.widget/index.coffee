# Cosmoduck · Orologio — Übersicht (legacy, lockable & draggable)
# Tecnica lucchetto + drag + persistenza localStorage (come Glass-Widgets di msavox).
# Orologio SVG a due strati con inversione colori HH/MM.

command: "date +%H:%M:%S"
refreshFrequency: 1000

style: """
  top: 18px
  left: 168px
  user-select: none
  pointer-events: auto
  cursor: grab

  &.locked
    cursor: default

  .lock-btn
    position: absolute
    top: 4px
    left: 100px
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
    bottom: 0
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

  .big
    font-family: 'CDBebas', sans-serif
    font-size: 118px
    letter-spacing: 2px
  .sc
    font-family: 'CDBebas', sans-serif
    font-size: 21px
    letter-spacing: 2px
"""

render: -> """
  <style>@font-face{font-family:'CDBebas';src:url('cosmoduck-clock.widget/fonts/BebasNeue-Regular.ttf') format('truetype');}</style>
  <div class="lock-btn" id="lock-toggle"></div>
  <svg width="200" height="210" viewBox="0 0 200 210">
    <text x="6" y="85"  class="big" fill="#5DADE2" transform="translate(-4,4)" id="hh1">00</text>
    <text x="6" y="85"  class="big" fill="#1F3A5F" id="hh2">00</text>
    <text x="6" y="180" class="big" fill="#1F3A5F" transform="translate(-4,4)" id="mm1">00</text>
    <text x="6" y="180" class="big" fill="#5DADE2" id="mm2">00</text>
    <text x="6" y="206" class="sc"><tspan fill="#AED6F1" id="ss">00</tspan><tspan fill="#C8D9E8"> SECONDS</tspan></text>
  </svg>
  <div class="pos-indicator" id="coords">T: 0 L: 0</div>
"""

afterRender: (domEl) ->
  P = "cosmoduck-clock"
  LOCK_SVG = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>'
  UNLOCK_SVG = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"></rect><path d="M7 11V7a5 5 0 0 1 9.9-1"></path></svg>'
  isLocked = localStorage.getItem("#{P}_locked") == 'true'
  savedTop = localStorage.getItem("#{P}_pos_top2")
  savedLeft = localStorage.getItem("#{P}_pos_left2")
  if savedTop and savedLeft
    domEl.style.top = savedTop
    domEl.style.left = savedLeft

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
  t = output.trim().split(':')
  return if t.length < 3
  $(domEl).find('#hh1,#hh2').text(t[0])
  $(domEl).find('#mm1,#mm2').text(t[1])
  $(domEl).find('#ss').text(t[2])
