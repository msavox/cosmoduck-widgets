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
  padding: 10px 0 10px 20px
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
    // 18 del margine piu' i 5 di padding della riga sotto: cosi' la "%" cade
    // sulla stessa colonna dei numeri invece che cinque punti piu' in la'.
    margin: 0 23px 3px 0
  .rule
    height: 1px
    margin: 5px 18px 5px 0
    background: var(--cd-rule, rgba(93,173,226,0.14))
  .prow
    position: relative
    display: flex
    align-items: baseline
    justify-content: space-between
    font-size: 10px
    line-height: 1.3
    margin-right: 18px
    padding: 0 5px
    border-radius: 3px
    overflow: hidden
  .prow .fill
    position: absolute
    top: 0
    bottom: 0
    left: 0
    width: 0
    border-radius: 3px
    background: var(--cd-fill, rgba(93,173,226,0.18))
    transition: width 0.4s ease-out
  .prow .n
    position: relative
    overflow: hidden
    white-space: nowrap
    text-overflow: ellipsis
    padding-right: 6px
    color: var(--cd-text, #C8D9E8)
  .prow .p
    position: relative
    flex: 0 0 auto
    color: var(--cd-accent, #5DADE2)
"""

render: -> """
  <style>@font-face{font-family:'CDAbel';src:url('cosmoduck-proc.widget/fonts/Abel-Regular.ttf') format('truetype');}</style>
  <div class="lock-btn" id="lock-toggle"></div>
  <div class="sec"><span>CPU</span><span>%</span></div>
  <div class="prow"><span class="fill" id="cf0"></span><span class="n" id="cn0"></span><span class="p" id="cp0"></span></div>
  <div class="prow"><span class="fill" id="cf1"></span><span class="n" id="cn1"></span><span class="p" id="cp1"></span></div>
  <div class="prow"><span class="fill" id="cf2"></span><span class="n" id="cn2"></span><span class="p" id="cp2"></span></div>
  <div class="rule"></div>
  <div class="sec"><span>MEMORY</span><span>%</span></div>
  <div class="prow"><span class="fill" id="rf0"></span><span class="n" id="rn0"></span><span class="p" id="rp0"></span></div>
  <div class="prow"><span class="fill" id="rf1"></span><span class="n" id="rn1"></span><span class="p" id="rp1"></span></div>
  <div class="prow"><span class="fill" id="rf2"></span><span class="n" id="rn2"></span><span class="p" id="rp2"></span></div>
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
  # La barra dietro ogni riga e' relativa al primo della lista, non a un 100%
  # assoluto: pcpu su otto core arriva a 800, e la domanda qui e' "chi sta
  # mangiando la macchina", che e' un confronto fra questi tre. Il minimo tiene
  # basse le barre quando non sta succedendo niente.
  fill = (arr, pfx, floor) ->
    top = Math.max(floor, Math.max(0, (parseFloat(p.p) or 0 for p in arr)...))
    for i in [0..2]
      p = arr[i]
      v = if p then (parseFloat(p.p) or 0) else 0
      $(domEl).find("##{pfx}n#{i}").text(if p then p.n else "")
      $(domEl).find("##{pfx}p#{i}").text(if p then p.p else "")
      $(domEl).find("##{pfx}f#{i}").css('width', if p then "#{(v / top * 100).toFixed(1)}%" else '0')
  fill((d.topcpu or []), 'c', 25)
  fill((d.topram or []), 'r', 8)
