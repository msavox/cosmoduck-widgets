# Cosmoduck · Meteo — Übersicht (legacy, lockable & draggable)
# OpenWeatherMap Como (IT), icona feather + temp Bebas.

command: "bash cosmoduck-weather.widget/scripts/weather.sh"
refreshFrequency: 60000

style: """
  top: 164px
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
  padding: 0 0 0 18px
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

  .row
    display: flex
    align-items: center
    gap: 10px
  .ico
    font-family: 'CDFeather'
    font-size: 30px
    color: #C8D9E8
  .temp
    font-family: 'CDBebas', sans-serif
    font-size: 32px
    color: #5DADE2
  .dots
    font-size: 12px
    letter-spacing: 1px
    margin: 2px 0
    opacity: 0.8
  .city
    font-size: 15px
    color: #5DADE2
    font-weight: 700
  .desc
    font-size: 14px
  .sub
    font-size: 11px
"""

render: -> """
  <style>
    @font-face{font-family:'CDFeather';src:url('cosmoduck-weather.widget/fonts/feather.ttf') format('truetype');}
    @font-face{font-family:'CDBebas';src:url('cosmoduck-weather.widget/fonts/BebasNeue-Regular.ttf') format('truetype');}
    @font-face{font-family:'CDAbel';src:url('cosmoduck-weather.widget/fonts/Abel-Regular.ttf') format('truetype');}
  </style>
  <div class="lock-btn" id="lock-toggle"></div>
  <div class="row"><span class="ico" id="wicon"></span><span class="temp" id="wtemp">--°C</span></div>
  <div class="dots">............</div>
  <div class="city" id="wcity">—</div>
  <div class="desc" id="wdesc"></div>
  <div class="sub" id="wwind">Wind speed : --m/s</div>
  <div class="sub" id="whum">Humidity : --%</div>
  <div class="pos-indicator" id="coords">T: 0 L: 0</div>
"""

afterRender: (domEl) ->
  P = "cosmoduck-weather"
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
    w = JSON.parse(output)
  catch e
    return
  return unless w and w.main and w.weather and w.weather[0]
  icons =
    "01d": 0xE9E3, "01n": 0xE9A3
    "02d": 0xE93A, "02n": 0xE93A, "03d": 0xE93A, "03n": 0xE93A
    "04d": 0xE93A, "04n": 0xE93A
    "09d": 0xE93B, "09n": 0xE93B, "10d": 0xE93E, "10n": 0xE93E
    "11d": 0xE93C, "11n": 0xE93C, "13d": 0xE93F, "13n": 0xE93F
    "50d": 0xEA10, "50n": 0xEA10
  code = w.weather[0].icon
  cp = icons[code] or 0xE93A
  desc = (w.weather[0].description or "").replace /\b\w/g, (c) -> c.toUpperCase()
  $(domEl).find('#wicon').text(String.fromCharCode(cp))
  $(domEl).find('#wtemp').text("#{Math.round(w.main.temp)}°C")
  $(domEl).find('#wcity').text(w.name)
  $(domEl).find('#wdesc').text(desc)
  $(domEl).find('#wwind').text("Wind speed : #{w.wind.speed}m/s")
  $(domEl).find('#whum').text("Humidity : #{w.main.humidity}%")
