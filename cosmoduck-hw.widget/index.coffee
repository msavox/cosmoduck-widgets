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
  color: #5DADE2
  font-family: 'CDAbel', -apple-system, sans-serif
  background: rgba(16,24,34,0.55)
  -webkit-backdrop-filter: blur(12px) saturate(1.2)
  backdrop-filter: blur(12px) saturate(1.2)
  border-radius: 22px
  border: 1px solid rgba(93,173,226,0.22)
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.07)
  padding: 0 0 0 20px
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
    font-size: 11px
    font-weight: 700
    color: #C8D9E8
    margin-bottom: 6px
  .hrow
    display: flex
    font-size: 11px
    font-weight: 700
    margin-bottom: 4px
  .hrow .k
    width: 74px
    flex: 0 0 auto
"""

render: -> """
  <style>@font-face{font-family:'CDAbel';src:url('cosmoduck-hw.widget/fonts/Abel-Regular.ttf') format('truetype');}</style>
  <div class="lock-btn" id="lock-toggle"></div>
  <div class="hdr">HARDWARE MONITOR</div>
  <div class="hrow"><span class="k">CPU Temp :</span><span class="v" id="hw-cputemp">--</span></div>
  <div class="hrow"><span class="k">GPU Temp :</span><span class="v" id="hw-gputemp">--</span></div>
  <div class="hrow"><span class="k">CPU Power :</span><span class="v" id="hw-cpupwr">--</span></div>
  <div class="hrow"><span class="k">GPU Power :</span><span class="v" id="hw-gpupwr">--</span></div>
  <div class="hrow"><span class="k">Sys Power :</span><span class="v" id="hw-syspwr">--</span></div>
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
  try
    d = JSON.parse(output)
  catch e
    return
  fmt = (v, unit, dec) ->
    if v? and v != null and not isNaN(v) then "#{(+v).toFixed(dec)}#{unit}" else "n/d"
  if d.nomacmon
    $(domEl).find('#hw-cputemp').text('macmon?')
    $(domEl).find('#hw-gputemp,#hw-cpupwr,#hw-gpupwr,#hw-syspwr').text('n/d')
    return
  $(domEl).find('#hw-cputemp').text(fmt(d.cputemp, '°C', 1))
  $(domEl).find('#hw-gputemp').text(fmt(d.gputemp, '°C', 1))
  $(domEl).find('#hw-cpupwr').text(fmt(d.cpupwr, ' W', 2))
  $(domEl).find('#hw-gpupwr').text(fmt(d.gpupwr, ' W', 2))
  $(domEl).find('#hw-syspwr').text(fmt(d.syspwr, ' W', 2))
