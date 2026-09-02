# Cosmoduck · Rete — Übersicht (legacy, lockable & draggable)
# SSID (icona feather) + Down/Up con sparkline SVG.

command: "bash cosmoduck-net.widget/scripts/collect.sh"
refreshFrequency: 1000

style: """
  top: 310px
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

  .ssid
    font-size: 13px
    font-weight: 700
    color: #5DADE2
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
      "<rect x='#{(i*bw).toFixed(1)}' y='#{(h-bh).toFixed(1)}' width='#{(bw*0.8).toFixed(1)}' height='#{bh.toFixed(1)}' fill='#AED6F1'></rect>"
    ).join('')
    "<svg width='#{w}' height='#{h}' style='display:block'><rect width='#{w}' height='#{h}' fill='#1F3A5F' fill-opacity='0.35'></rect>#{bars}</svg>"
  domEl.querySelector('#dspark').innerHTML = spark(dh)
  domEl.querySelector('#uspark').innerHTML = spark(uh)
