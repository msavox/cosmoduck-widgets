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
  color: var(--cd-text, #C8D9E8)
  font-family: 'CDAbel', -apple-system, sans-serif
  background: var(--cd-glass, rgba(16,24,34,0.55))
  -webkit-backdrop-filter: blur(12px) saturate(1.2)
  backdrop-filter: blur(12px) saturate(1.2)
  border-radius: 22px
  border: 1px solid var(--cd-border, rgba(93,173,226,0.22))
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.07)
  padding: 0 0 0 16px
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

  .row
    display: flex
    align-items: baseline
    gap: 9px
  .ico
    font-family: 'CDFeather'
    font-size: 27px
    line-height: 1
    color: var(--cd-text, #C8D9E8)
    transform: translateY(3px)
  .temp
    font-family: 'CDBebas', sans-serif
    font-size: 31px
    line-height: 1
    color: var(--cd-accent, #5DADE2)
  .today
    font-size: 9px
    line-height: 1.3
    opacity: 0.7
    align-self: center
    margin-left: 1px
  .today .g
    font-family: 'CDFeather'
    font-size: 8px
    margin-right: 2px
    opacity: 0.8
  .city
    font-size: 14px
    line-height: 1.2
    color: var(--cd-accent, #5DADE2)
    font-weight: 700
  .stats
    display: flex
    gap: 12px
    font-size: 11px
    line-height: 1.4
    opacity: 0.85
  .stats .g
    font-family: 'CDFeather'
    font-size: 11px
    color: var(--cd-mid, #85C1E9)
    margin-right: 3px
  .rule
    height: 1px
    margin: 4px 14px 4px 0
    background: var(--cd-rule, rgba(93,173,226,0.14))
  .fc
    display: grid
    grid-template-columns: repeat(5, 1fr)
    text-align: center
    margin-right: 14px
  .fc .d
    font-size: 9px
    line-height: 1.2
    opacity: 0.5
  .fc .i
    font-family: 'CDFeather'
    font-size: 14px
    line-height: 1.4
    color: var(--cd-mid, #85C1E9)
  // Feather non ha un "sole dietro le nuvole", e "poche nubi" (codice 02) non
  // e' ne' sereno ne' coperto: si compone con i due glifi che ci sono.
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
  .fc .hi
    font-size: 9px
    line-height: 1.25
    color: var(--cd-accent, #5DADE2)
  .fc .lo
    font-size: 9px
    line-height: 1.25
    opacity: 0.45
"""

render: -> """
  <style>
    @font-face{font-family:'CDFeather';src:url('cosmoduck-weather.widget/fonts/feather.ttf') format('truetype');}
    @font-face{font-family:'CDBebas';src:url('cosmoduck-weather.widget/fonts/BebasNeue-Regular.ttf') format('truetype');}
    @font-face{font-family:'CDAbel';src:url('cosmoduck-weather.widget/fonts/Abel-Regular.ttf') format('truetype');}
  </style>
  <div class="lock-btn" id="lock-toggle"></div>
  <div class="row">
    <span class="ico" id="wicon"></span><span class="temp" id="wtemp">--°</span>
    <span class="today"><div><span class="g" id="gup"></span><span id="wmax">--°</span></div><div><span class="g" id="gdn"></span><span id="wmin">--°</span></div></span>
  </div>
  <div class="city" id="wcity">—</div>
  <div class="stats">
    <span><span class="g" id="gwind"></span><span id="wwind">--</span></span>
    <span><span class="g" id="ghum"></span><span id="whum">--</span></span>
  </div>
  <div class="rule"></div>
  <div class="fc" id="wfc"></div>
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
    data = JSON.parse(output)
  catch e
    return
  return unless data
  # Lo script emette { current, forecast }. Una cache vecchia poteva essere il
  # JSON nudo di OWM: in quel caso lo si prende com'e' e si sta senza previsioni.
  w = data.current or data
  fc = data.forecast or []
  return unless w and w.main and w.weather and w.weather[0]
  # Codepoint nel font Feather in dotazione (vedi fonts/feather.ttf).
  icons =
    "01d": 0xE9E3, "01n": 0xE9A3
    "03d": 0xE93A, "03n": 0xE93A
    "04d": 0xE93A, "04n": 0xE93A
    "09d": 0xE93B, "09n": 0xE93B, "10d": 0xE93E, "10n": 0xE93E
    "11d": 0xE93C, "11n": 0xE93C, "13d": 0xE93F, "13n": 0xE93F
    "50d": 0xEA10, "50n": 0xEA10
  WIND = 0xEA10       # tre linee mosse
  DROP = 0xE95A       # goccia
  UP   = 0xE914       # freccia su
  DOWN = 0xE90C       # freccia giu'
  SUN   = 0xE9E3
  MOON  = 0xE9A3
  CLOUD = 0xE93A
  ch = (cp) -> String.fromCharCode(cp)
  # "02" e' poche nubi: mostrarlo come coperto e' quello che rendeva la
  # settimana tutta uguale anche quando uguale non era.
  glyph = (code) ->
    if code is '02d' or code is '02n'
      back = if code is '02d' then SUN else MOON
      """<span class="mix"><span class="s">#{ch(back)}</span><span class="c">#{ch(CLOUD)}</span></span>"""
    else
      ch(icons[code] or CLOUD)
  $(domEl).find('#wicon').html(glyph(w.weather[0].icon))
  $(domEl).find('#wtemp').text("#{Math.round(w.main.temp)}°")
  $(domEl).find('#wcity').text(w.name)
  # La minima di oggi puo' essere gia' passata: l'API gratuita da' solo le ore
  # che restano, quindi qui "oggi" vuol dire da adesso a mezzanotte.
  today = data.today or { min: Math.round(w.main.temp), max: Math.round(w.main.temp) }
  $(domEl).find('#gup').text(String.fromCharCode(UP))
  $(domEl).find('#gdn').text(String.fromCharCode(DOWN))
  $(domEl).find('#wmax').text("#{today.max}°")
  $(domEl).find('#wmin').text("#{today.min}°")
  $(domEl).find('#gwind').text(String.fromCharCode(WIND))
  $(domEl).find('#ghum').text(String.fromCharCode(DROP))
  $(domEl).find('#wwind').text("#{Math.round(w.wind.speed * 10) / 10} m/s")
  $(domEl).find('#whum').text("#{w.main.humidity}%")
  days = for d in fc
    """<div><div class="d">#{d.dow}</div><div class="i">#{glyph(d.icon)}</div>""" +
    """<div class="hi">#{d.max}°</div><div class="lo">#{d.min}°</div></div>"""
  $(domEl).find('#wfc').html(days.join(''))
