# Cosmoduck · Tutto in uno — Übersicht (legacy, lockable & draggable)
#
# Una card sola con meteo, sistema, sensori, rete, processi e uso di Claude:
# gli stessi dati delle card separate, per chi preferisce un blocco unico
# invece di una colonna. Orologio e calendario restano fuori: sono un'altra
# cosa, e su quelli la colonna funziona meglio.
#
# I dati arrivano da scripts/collect.sh, che richiama i collector dei singoli
# widget in parallelo: la logica di raccolta resta scritta una volta sola.

command: "bash cosmoduck-all.widget/scripts/collect.sh"
refreshFrequency: 5000

style: """
  top: 18px
  left: 400px
  width: 272px
  height: 450px
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
  padding: 12px 14px
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
    opacity: 0.45
    margin-bottom: 4px
  .sec .st
    letter-spacing: 0.5px
  .rule
    height: 1px
    margin: 6px 0
    background: var(--cd-rule, rgba(93,173,226,0.14))
  .gly
    font-family: 'CDFeather'
    color: var(--cd-mid, #85C1E9)

  .wx-now
    display: flex
    align-items: baseline
    gap: 8px
    margin-bottom: 4px
  .wx-now .ico
    font-family: 'CDFeather'
    font-size: 22px
    line-height: 1
    color: var(--cd-text, #C8D9E8)
    transform: translateY(2px)
  .wx-now .t
    font-family: 'CDBebas', sans-serif
    font-size: 26px
    line-height: 1
    color: var(--cd-accent, #5DADE2)
  .wx-now .mm
    font-size: 9px
    line-height: 1.25
    opacity: 0.7
  .wx-now .stats
    margin-left: auto
    display: flex
    gap: 10px
    font-size: 9.5px
    opacity: 0.85
  .wx-now .stats .gly
    font-size: 10px
    margin-right: 3px
  .fc
    display: grid
    grid-template-columns: repeat(5, 1fr)
    text-align: center
    max-width: 100%
  .fc .d
    font-size: 8px
    opacity: 0.5
  .fc .i
    font-family: 'CDFeather'
    font-size: 13px
    line-height: 1.45
    color: var(--cd-mid, #85C1E9)
  .fc .hi
    font-size: 8.5px
    line-height: 1.2
    color: var(--cd-accent, #5DADE2)
  .fc .lo
    font-size: 8.5px
    line-height: 1.2
    opacity: 0.45
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

  .sysrow
    display: flex
    align-items: center
    gap: 12px
  .rings
    flex: 0 0 auto
  .rings circle
    fill: none
    stroke-width: 3.5
    stroke-linecap: round
  .rings .bg
    opacity: 0.22
  .r-cpu
    stroke: var(--cd-accent, #5DADE2)
  .r-mem
    stroke: var(--cd-mid, #85C1E9)
  .r-disk
    stroke: var(--cd-deep, #2874A6)
  .rings text
    font-family: 'CDAbel', sans-serif
    font-size: 7.5px
    letter-spacing: 0.7px
    fill: var(--cd-text, #C8D9E8)
    opacity: 0.5
    text-anchor: middle
  .syslegend
    flex: 1 1 auto
  .syslegend .r
    display: flex
    align-items: baseline
    font-size: 11.5px
    line-height: 1.4
    font-weight: 700
  .syslegend .k
    width: 42px
    flex: 0 0 auto
    opacity: 0.85
  .syslegend .v
    color: var(--cd-accent, #5DADE2)
  .syslegend .sub
    font-size: 8px
    letter-spacing: 1.2px
    opacity: 0.45
    margin: 4px 0 1px

  .grid2
    display: grid
    grid-template-columns: 1fr 1fr
    column-gap: 12px
  .trow
    display: flex
    align-items: baseline
    gap: 6px
    margin-bottom: 4px
  .trow .k
    width: 22px
    flex: 0 0 auto
    font-size: 9px
    letter-spacing: 0.5px
    opacity: 0.6
  .trow .bar
    flex: 1 1 auto
    align-self: center
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
    font-size: 10.5px
    color: var(--cd-accent, #5DADE2)
  .pw
    display: grid
    grid-template-columns: repeat(3, 1fr)
  .pw .l
    font-size: 8px
    letter-spacing: 0.7px
    opacity: 0.45
  .pw .n
    font-size: 10.5px
    line-height: 1.25
    color: var(--cd-mid, #85C1E9)

  .netrow
    display: flex
    align-items: center
    gap: 8px
    margin-bottom: 2px
  .netrow .k
    width: 66px
    flex: 0 0 auto
    font-size: 10.5px
  .netrow .k .gly
    font-size: 9px
    margin-right: 4px
  .netrow .sp
    flex: 1 1 auto
    height: 15px
  .netrow .sp svg
    width: 100%
    height: 15px
    display: block
  .netrow .sp polyline
    fill: none
    stroke: var(--cd-accent, #5DADE2)
    stroke-width: 1
    stroke-linejoin: round
    opacity: 0.8
  .netrow .sp polygon
    fill: var(--cd-fill, rgba(93,173,226,0.18))
    stroke: none

  .prow
    position: relative
    display: flex
    align-items: baseline
    justify-content: space-between
    font-size: 10px
    line-height: 1.4
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
  .prow .p
    position: relative
    flex: 0 0 auto
    color: var(--cd-accent, #5DADE2)

  .cc
    display: flex
    align-items: baseline
    gap: 10px
    font-size: 9.5px
  .cc .model
    font-weight: 700
    color: var(--cd-accent, #5DADE2)
  .cc .q
    display: flex
    align-items: baseline
    gap: 5px
    opacity: 0.9
  .cc .q b
    font-weight: 400
    font-size: 8px
    letter-spacing: 1px
    opacity: 0.55
  .cc .mini
    width: 30px
    height: 3px
    border-radius: 2px
    background: var(--cd-track, rgba(31,58,95,0.55))
    overflow: hidden
    align-self: center
  .cc .mini i
    display: block
    height: 100%
    width: 0
    background: var(--cd-accent, #5DADE2)
"""

render: -> """
  <style>
    @font-face{font-family:'CDAbel';src:url('cosmoduck-all.widget/fonts/Abel-Regular.ttf') format('truetype');}
    @font-face{font-family:'CDBebas';src:url('cosmoduck-all.widget/fonts/BebasNeue-Regular.ttf') format('truetype');}
    @font-face{font-family:'CDFeather';src:url('cosmoduck-all.widget/fonts/feather.ttf') format('truetype');}
  </style>
  <div class="lock-btn" id="lock-toggle"></div>

  <div class="sec"><span>WEATHER</span><span class="st" id="a-city">—</span></div>
  <div class="wx-now">
    <span class="ico" id="a-wicon"></span>
    <span class="t" id="a-wtemp">--°</span>
    <span class="mm"><div id="a-wmax">--</div><div id="a-wmin">--</div></span>
    <span class="stats">
      <span><span class="gly" id="a-gwind"></span><span id="a-wind">--</span></span>
      <span><span class="gly" id="a-ghum"></span><span id="a-hum">--</span></span>
    </span>
  </div>
  <div class="fc" id="a-fc"></div>

  <div class="rule"></div>
  <div class="sec"><span>SYSTEM</span><span class="st" id="a-sysst"></span></div>
  <div class="sysrow">
    <svg class="rings" width="106" height="42" viewBox="0 0 106 42">
      <circle class="bg r-cpu"  cx="14" cy="15" r="12"></circle>
      <circle class="fg r-cpu"  id="a-ring-cpu"  cx="14" cy="15" r="12" stroke-dasharray="0 75.40" transform="rotate(-90 14 15)"></circle>
      <circle class="bg r-mem"  cx="52" cy="15" r="12"></circle>
      <circle class="fg r-mem"  id="a-ring-mem"  cx="52" cy="15" r="12" stroke-dasharray="0 75.40" transform="rotate(-90 52 15)"></circle>
      <circle class="bg r-disk" cx="90" cy="15" r="12"></circle>
      <circle class="fg r-disk" id="a-ring-disk" cx="90" cy="15" r="12" stroke-dasharray="0 75.40" transform="rotate(-90 90 15)"></circle>
      <text x="14" y="39">CPU</text>
      <text x="52" y="39">RAM</text>
      <text x="90" y="39">DISK</text>
    </svg>
    <div class="syslegend">
      <div class="r"><span class="k">LOAD</span><span class="v" id="a-load">--%</span></div>
      <div class="sub">FREE</div>
      <div class="r"><span class="k">RAM</span><span class="v" id="a-ramfree">--</span></div>
      <div class="r"><span class="k">DISK</span><span class="v" id="a-diskfree">--</span></div>
    </div>
  </div>

  <div class="rule"></div>
  <div class="sec"><span>SENSORS</span><span class="st" id="a-battst"></span></div>
  <div class="grid2">
    <div class="trow" id="a-row-cpu"><span class="k">CPU</span><span class="bar"><i id="a-bar-cpu"></i></span><span class="v" id="a-cputemp">--</span></div>
    <div class="trow" id="a-row-gpu"><span class="k">GPU</span><span class="bar"><i id="a-bar-gpu"></i></span><span class="v" id="a-gputemp">--</span></div>
  </div>
  <div class="grid2">
    <div class="trow" id="a-row-bat"><span class="k">BAT</span><span class="bar"><i id="a-bar-bat"></i></span><span class="v" id="a-battpct">--</span></div>
    <div class="pw">
      <div><div class="l">CPU W</div><div class="n" id="a-cpupwr">--</div></div>
      <div><div class="l">GPU W</div><div class="n" id="a-gpupwr">--</div></div>
      <div><div class="l">SYS W</div><div class="n" id="a-syspwr">--</div></div>
    </div>
  </div>

  <div class="rule"></div>
  <div class="sec"><span>NETWORK</span><span class="st" id="a-ssid">—</span></div>
  <div class="netrow"><span class="k"><span class="gly" id="a-gdown"></span><span id="a-down">--</span></span><span class="sp" id="a-spdown"></span></div>
  <div class="netrow"><span class="k"><span class="gly" id="a-gup"></span><span id="a-up">--</span></span><span class="sp" id="a-spup"></span></div>

  <div class="rule"></div>
  <div class="sec"><span>PROCESSES</span><span class="st">CPU % · MEM %</span></div>
  <div class="grid2">
    <div>
      <div class="prow"><span class="fill" id="a-cf0"></span><span class="n" id="a-cn0"></span><span class="p" id="a-cp0"></span></div>
      <div class="prow"><span class="fill" id="a-cf1"></span><span class="n" id="a-cn1"></span><span class="p" id="a-cp1"></span></div>
      <div class="prow"><span class="fill" id="a-cf2"></span><span class="n" id="a-cn2"></span><span class="p" id="a-cp2"></span></div>
    </div>
    <div>
      <div class="prow"><span class="fill" id="a-rf0"></span><span class="n" id="a-rn0"></span><span class="p" id="a-rp0"></span></div>
      <div class="prow"><span class="fill" id="a-rf1"></span><span class="n" id="a-rn1"></span><span class="p" id="a-rp1"></span></div>
      <div class="prow"><span class="fill" id="a-rf2"></span><span class="n" id="a-rn2"></span><span class="p" id="a-rp2"></span></div>
    </div>
  </div>

  <div class="rule"></div>
  <div class="cc">
    <span class="model" id="a-ccmodel">—</span>
    <span class="q"><b>SESS</b><span class="mini"><i id="a-ccsbar"></i></span><span id="a-ccs">--</span></span>
    <span class="q"><b>WEEK</b><span class="mini"><i id="a-ccwbar"></i></span><span id="a-ccw">--</span></span>
  </div>

  <div class="pos-indicator" id="coords">T: 0 L: 0</div>
"""
afterRender: (domEl) ->
  P = "cosmoduck-all"
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
  return unless d
  $el = $(domEl)
  num = (v, dec) -> if v? and not isNaN(v) then (+v).toFixed(dec) else 'n/d'
  # Codepoint nel font Feather in dotazione (vedi fonts/feather.ttf).
  ICONS =
    "01d": 0xE9E3, "01n": 0xE9A3
    "03d": 0xE93A, "03n": 0xE93A
    "04d": 0xE93A, "04n": 0xE93A
    "09d": 0xE93B, "09n": 0xE93B, "10d": 0xE93E, "10n": 0xE93E
    "11d": 0xE93C, "11n": 0xE93C, "13d": 0xE93F, "13n": 0xE93F
    "50d": 0xEA10, "50n": 0xEA10
  SUN = 0xE9E3; MOON = 0xE9A3; CLOUD = 0xE93A
  WIND = 0xEA10; DROP = 0xE95A; DOWN = 0xE90C; UP = 0xE914
  ch = (cp) -> String.fromCharCode(cp)
  # "02" e' poche nubi: ne' sereno ne' coperto, e Feather non ha un sole dietro
  # le nuvole. Si compone con i due glifi che ci sono.
  glyph = (code) ->
    if code is '02d' or code is '02n'
      back = if code is '02d' then SUN else MOON
      """<span class="mix"><span class="s">#{ch(back)}</span><span class="c">#{ch(CLOUD)}</span></span>"""
    else
      ch(ICONS[code] or CLOUD)

  # ── meteo ───────────────────────────────────────────────────────────────────
  wx = d.wx
  w = wx?.current
  if w?.main and w?.weather?[0]
    $el.find('#a-wicon').html(glyph(w.weather[0].icon))
    $el.find('#a-wtemp').text("#{Math.round(w.main.temp)}°")
    $el.find('#a-city').text((w.name or '').toUpperCase())
    $el.find('#a-gwind').text(ch(WIND))
    $el.find('#a-ghum').text(ch(DROP))
    $el.find('#a-wind').text("#{Math.round(w.wind.speed * 10) / 10} m/s")
    $el.find('#a-hum').text("#{w.main.humidity}%")
    today = wx.today or { min: Math.round(w.main.temp), max: Math.round(w.main.temp) }
    $el.find('#a-wmax').text("#{ch(UP)} #{today.max}°")
    $el.find('#a-wmin').text("#{ch(DOWN)} #{today.min}°")
    $el.find('#a-wmax,#a-wmin').css('font-family', "'CDFeather', 'CDAbel', sans-serif")
    days = for day in (wx.forecast or [])
      """<div><div class="d">#{day.dow}</div><div class="i">#{glyph(day.icon)}</div>""" +
      """<div class="hi">#{day.max}°</div><div class="lo">#{day.min}°</div></div>"""
    $el.find('#a-fc').html(days.join(''))

  # ── sistema ────────────────────────────────────────────────────────────────
  sys = d.sys
  if sys
    ring = (id, pct) ->
      f = Math.max(0, Math.min(100, pct or 0)) / 100
      $el.find(id).attr('stroke-dasharray', "#{(f * 75.40).toFixed(2)} 75.40")
    ring('#a-ring-cpu', sys.cpu)
    ring('#a-ring-mem', sys.mem)
    ring('#a-ring-disk', sys.diskData)
    $el.find('#a-load').text("#{sys.cpu}%")
    $el.find('#a-ramfree').text("#{sys.memFreeGB}GB")
    $el.find('#a-diskfree').text("#{sys.diskFreeGB}GB")

  # ── sensori e batteria ─────────────────────────────────────────────────────
  hw = d.hw
  if hw
    gauge = (bar, row, v, lo, hi, hot) ->
      if v? and not isNaN(v)
        pct = Math.max(0, Math.min(100, (v - lo) / (hi - lo) * 100))
        $el.find(bar).css('width', "#{pct.toFixed(1)}%")
        $el.find(row).toggleClass('hot', hot)
      else
        $el.find(bar).css('width', '0%')
    gauge('#a-bar-cpu', '#a-row-cpu', hw.cputemp, 30, 95, hw.cputemp >= 80)
    gauge('#a-bar-gpu', '#a-row-gpu', hw.gputemp, 30, 95, hw.gputemp >= 80)
    $el.find('#a-cputemp').text(if hw.cputemp? then "#{num(hw.cputemp, 1)}°" else 'n/d')
    $el.find('#a-gputemp').text(if hw.gputemp? then "#{num(hw.gputemp, 1)}°" else 'n/d')
    # Su parecchi Mac Apple Silicon macmon non riceve il canale della CPU e
    # riporta zero fisso: uno zero li' si legge come una misura, quindi quando
    # il sistema consuma e il canale no, si dice n/d.
    dead = (v) -> (not v?) or (v is 0 and hw.syspwr? and hw.syspwr > 1)
    $el.find('#a-cpupwr').text(if dead(hw.cpupwr) then 'n/d' else num(hw.cpupwr, 2))
    $el.find('#a-gpupwr').text(if dead(hw.gpupwr) then 'n/d' else num(hw.gpupwr, 2))
    $el.find('#a-syspwr').text(num(hw.syspwr, 2))
    b = hw.batt
    if b?.pct?
      gauge('#a-bar-bat', '#a-row-bat', b.pct, 0, 100, b.pct <= 20 and b.state isnt 'charging')
      $el.find('#a-battpct').text("#{b.pct}%")
      hhmm = if b.mins? then "#{Math.floor(b.mins / 60)}H#{String(b.mins % 60).padStart(2, '0')}" else null
      $el.find('#a-battst').text(
        switch b.state
          when 'charging'    then (if hhmm then "TO FULL #{hhmm}" else 'CHARGING')
          when 'discharging' then (if hhmm then "#{hhmm} LEFT" else 'ON BATTERY')
          when 'charged', 'finishing charge' then 'FULL'
          else (if b.ac then 'AC' else (hhmm or '')))

  # ── rete ───────────────────────────────────────────────────────────────────
  net = d.net
  if net
    $el.find('#a-ssid').text((net.ssid or '').toUpperCase())
    $el.find('#a-gdown').text(ch(DOWN))
    $el.find('#a-gup').text(ch(UP))
    $el.find('#a-down').text(net.down or '--')
    $el.find('#a-up').text(net.up or '--')
    # Lo storico sta appeso all'elemento e non in una variabile di modulo: un
    # assegnamento nudo fra due chiavi chiuderebbe l'object literal del widget,
    # e Ubersicht si ritroverebbe una card senza command ne' render.
    MAX = 40
    trace = (key, sel, v) ->
      hist = $el.data(key) or []
      hist.push(Math.max(0, +v or 0))
      hist.shift() while hist.length > MAX
      $el.data(key, hist)
      return if hist.length < 2
      W = 100; H = 15
      top = Math.max(1, Math.max(hist...))
      step = W / (MAX - 1)
      pts = (for y, i in hist
        x = (i + MAX - hist.length) * step
        "#{x.toFixed(1)},#{(H - 1 - (y / top) * (H - 2)).toFixed(1)}").join(' ')
      first = pts.split(' ')[0].split(',')[0]
      last = pts.split(' ')[hist.length - 1].split(',')[0]
      $el.find(sel).html("""<svg viewBox="0 0 #{W} #{H}" preserveAspectRatio="none">
        <polygon points="#{first},#{H} #{pts} #{last},#{H}"></polygon>
        <polyline points="#{pts}"></polyline></svg>""")
    trace('dhist', '#a-spdown', net.dbytes)
    trace('uhist', '#a-spup', net.ubytes)

  # ── processi ───────────────────────────────────────────────────────────────
  pr = d.proc
  if pr
    # La barra dietro ogni riga e' relativa al primo della lista: pcpu su otto
    # core arriva a 800, e la domanda qui e' chi sta mangiando la macchina.
    fill = (arr, pfx, floor) ->
      top = Math.max(floor, Math.max(0, (parseFloat(p.p) or 0 for p in arr)...))
      for i in [0..2]
        p = arr[i]
        v = if p then (parseFloat(p.p) or 0) else 0
        $el.find("##{pfx}n#{i}").text(if p then p.n else '')
        $el.find("##{pfx}p#{i}").text(if p then p.p else '')
        $el.find("##{pfx}f#{i}").css('width', if p then "#{(v / top * 100).toFixed(1)}%" else '0')
    fill((pr.topcpu or []), 'a-c', 25)
    fill((pr.topram or []), 'a-r', 8)

  # ── Claude ─────────────────────────────────────────────────────────────────
  cc = d.cc
  if cc
    $el.find('#a-ccmodel').text(cc.model or '—')
    for [q, bar, val] in [[cc.session, '#a-ccsbar', '#a-ccs'], [cc.week, '#a-ccwbar', '#a-ccw']]
      continue unless q
      $el.find(bar).css('width', "#{Math.max(0, Math.min(100, q.pct or 0))}%")
      $el.find(val).text("#{q.pct}%")
  return
