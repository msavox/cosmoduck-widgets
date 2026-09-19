# Cosmoduck · Processi — Übersicht (legacy, lockable & draggable)
# TOP CPU (3) + TOP RAM (3).

command: "bash cosmoduck-proc.widget/scripts/collect.sh"
refreshFrequency: 2000

style: """
  top: 456px
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

  .hdr
    font-size: 11px
    font-weight: 700
    color: var(--cd-text, #C8D9E8)
    margin-bottom: 3px
  .hdr2
    margin-top: 8px
  .prow
    display: flex
    font-size: 11px
    font-weight: 700
  .prow .n
    width: 74px
    overflow: hidden
    white-space: nowrap
  .prow .p
    color: var(--cd-accent, #5DADE2)
"""

render: -> """
  <style>@font-face{font-family:'CDAbel';src:url('cosmoduck-proc.widget/fonts/Abel-Regular.ttf') format('truetype');}</style>
  <div class="lock-btn" id="lock-toggle"></div>
  <div class="hdr">TOP CPU PROCESSES</div>
  <div class="prow"><span class="n" id="cn0"></span><span class="p" id="cp0"></span></div>
  <div class="prow"><span class="n" id="cn1"></span><span class="p" id="cp1"></span></div>
  <div class="prow"><span class="n" id="cn2"></span><span class="p" id="cp2"></span></div>
  <div class="hdr hdr2">TOP RAM PROCESSES</div>
  <div class="prow"><span class="n" id="rn0"></span><span class="p" id="rp0"></span></div>
  <div class="prow"><span class="n" id="rn1"></span><span class="p" id="rp1"></span></div>
  <div class="prow"><span class="n" id="rn2"></span><span class="p" id="rp2"></span></div>
  <div class="pos-indicator" id="coords">T: 0 L: 0</div>
"""

afterRender: (domEl) ->
  P = "cosmoduck-proc"
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
  fill = (arr, pfx) ->
    for i in [0..2]
      p = arr[i]
      $(domEl).find("##{pfx}n#{i}").text(if p then p.n else "")
      $(domEl).find("##{pfx}p#{i}").text(if p then "#{p.p}%" else "")
  fill((d.topcpu or []), 'c')
  fill((d.topram or []), 'r')
