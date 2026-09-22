# Cosmoduck · Tutto in uno — Übersicht (legacy, lockable & draggable)
#
# Una card sola con meteo, sistema, sensori, rete, processi e uso di Claude:
# gli stessi dati delle card separate, per chi preferisce un blocco unico
# invece di una colonna. Orologio e calendario restano fuori: sono un'altra
# cosa, e su quelli la colonna funziona meglio.
#
# I dati arrivano da scripts/collect.sh, che richiama i collector dei singoli
# widget in parallelo: la logica di raccolta resta scritta una volta sola.

# Rimettere la card dove l'hai lasciata, prima che si veda altrove.
#
# Nota sui limiti: il default qui sotto e' l'angolo in alto a sinistra, come le
# altre card del set. Non e' un dettaglio estetico -- e' il posto in cui la card
# si vede per la prima frazione di secondo, prima che qualcuno possa spostarla,
# e piu' e' vicino a dove la tieni meno si nota.
#
# Lo style qui sotto e' statico: lo compila il server con Stylus e non sa niente
# di dove hai trascinato la card, che vive nel localStorage del browser. E
# afterRender -- dove la posizione viene ripristinata -- Ubersicht lo chiama
# solo quando il comando ritorna, che per questo pannello e' un secondo dopo:
# in quel secondo la card sta alla posizione di default, e si vede.
#
# Questo blocco invece gira nel browser appena la pagina carica il modulo, cioe'
# prima che il comando parta. L'elemento magari non c'e' ancora, quindi lo si
# aspetta a piccoli passi per un secondo scarso. Si scrive sullo stile inline,
# non in un foglio: cosi' il trascinamento, che scrive negli stessi campi,
# continua a funzionare.
do ->
  try
    savedTop = localStorage.getItem('cosmoduck-all_pos_top2')
    savedLeft = localStorage.getItem('cosmoduck-all_pos_left2')
    return unless savedTop and savedLeft
    tries = 0
    place = ->
      el = document.querySelector('[id^="cosmoduck-all-widget"]')
      if el
        el.style.top = savedTop
        el.style.left = savedLeft
        return
      tries += 1
      setTimeout(place, 25) if tries < 40
    place()
  catch error
    # Nessun browser: e' il server che sta leggendo il file, e li' non c'e'
    # niente da posizionare.
    return

command: "bash cosmoduck-all.widget/scripts/collect.sh"
refreshFrequency: 5000

style: """
  top: 18px
  left: 12px
  width: 214.2px
  height: 884px
  box-sizing: border-box
  overflow: hidden
  color: var(--cd-text, #C8D9E8)
  font-family: 'CDAbel', -apple-system, sans-serif
  background: var(--cd-glass, rgba(16,24,34,0.55))
  -webkit-backdrop-filter: blur(12px) saturate(1.2)
  backdrop-filter: blur(12px) saturate(1.2)
  border-radius: 24.2px
  border: 1px solid var(--cd-border, rgba(93,173,226,0.22))
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.07)
  padding: 13.2px 15.4px
  display: flex
  flex-direction: column
  justify-content: center
  user-select: none
  pointer-events: auto
  cursor: grab

  // La card e' una colonna flex, e un figlio flex per difetto si lascia
  // comprimere: quando il contenuto sfiora l'altezza, le righe dei processi si
  // schiacciavano l'una sull'altra invece di restare intere. Qui nessuno si
  // stringe -- se proprio non ci sta, meglio che si veda.
  > *
    flex: 0 0 auto

  &.locked
    cursor: default

  .lock-btn
    position: absolute
    top: 11px
    right: 9.9px
    color: var(--cd-bright, #AED6F1)
    width: 16.5px
    height: 16.5px
    opacity: 0
    cursor: pointer
    transition: opacity 0.2s
    z-index: 10
  &:hover .lock-btn
    opacity: 0.55
  .lock-btn:hover
    opacity: 1
  .lock-btn svg
    width: 16.5px
    height: 16.5px
    display: block

  .pos-indicator
    position: absolute
    bottom: 2.2px
    left: 50%
    transform: translateX(-50%)
    background: rgba(0,0,0,0.6)
    color: #fff
    font-size: 8.8px
    padding: 2.2px 8.8px
    border-radius: 11px
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
    font-size: 10.5px
    letter-spacing: 1.5px
    opacity: 0.45
    margin-bottom: 4.4px
  .sec .st
    letter-spacing: 0.6px
  .sec2
    margin-top: 6.6px
  .rule
    height: 1px
    margin: 6.6px 0
    background: var(--cd-rule, rgba(93,173,226,0.14))
  .gly
    font-family: 'CDFeather'
    color: var(--cd-mid, #85C1E9)

  // Il meteo di adesso sta su una griglia di due righe e tre colonne, non su
  // due righe indipendenti: la prima colonna tiene temperatura e vento, la
  // seconda le estreme di oggi e l'umidita'. Cosi' l'umidita' cade sotto i due
  // numeri della giornata invece di finire a meta' strada, e le due colonne si
  // allargano insieme al testo piu' largo che contengono. La terza -- lo spazio
  // che restava vuoto a destra -- e' il nome della citta'.
  .wx
    display: grid
    grid-template-columns: auto auto 1fr
    column-gap: 13.2px
    row-gap: 3.3px
    align-items: center
    margin-bottom: 4.4px
  .wx .now
    grid-column: 1
    grid-row: 1
    display: flex
    align-items: baseline
    gap: 8.8px
  .wx .ico
    font-family: 'CDFeather'
    font-size: 24.2px
    line-height: 1
    color: var(--cd-text, #C8D9E8)
    transform: translateY(2.2px)
  .wx .t
    font-family: 'CDBebas', sans-serif
    font-size: 28.6px
    line-height: 1
    color: var(--cd-accent, #5DADE2)
  // Massima e minima di oggi: centrate sul blocco della temperatura invece di
  // appoggiarsi alla sua linea di base, che le faceva pendere in basso. La
  // freccia sta in una colonnina di larghezza fissa, cosi' i due numeri si
  // incolonnano invece di ballare a seconda della freccia.
  .wx .mm
    grid-column: 2
    grid-row: 1
    font-size: 12.1px
    line-height: 1.3
    opacity: 0.75
  .wx .mm .g
    font-family: 'CDFeather'
    display: inline-block
    width: 13.2px
    font-size: 9.9px
    opacity: 0.7
  // Come nella card meteo da sola: non la scritta piccola e spaziata
  // dell'intestazione, ma il nome scritto per esteso, nel colore d'accento.
  .wx .city
    grid-column: 3
    grid-row: 1 / span 2
    align-self: start
    text-align: left
    font-size: 15.4px
    line-height: 1.2
    font-weight: 700
    color: var(--cd-accent, #5DADE2)
    overflow: hidden
    text-overflow: ellipsis
    white-space: nowrap
  .wx .wind
    grid-column: 1
    grid-row: 2
  .wx .hum
    grid-column: 2
    grid-row: 2
  .wx .wind, .wx .hum
    font-size: 11px
    opacity: 0.85
  .wx .wind .gly, .wx .hum .gly
    font-size: 11px
    display: inline-block
    width: 13.2px
  .fc
    display: grid
    grid-template-columns: repeat(5, 1fr)
    text-align: center
    max-width: 100%
  .fc .d
    font-size: 9.9px
    opacity: 0.5
  // La striscia occupa tutta la larghezza della card, e a 183 punti ogni giorno
  // ne ha piu' di 36: icone e temperature possono permettersi di crescere.
  .fc .i
    font-family: 'CDFeather'
    font-size: 18.7px
    line-height: 1.45
    color: var(--cd-mid, #85C1E9)
  .fc .hi
    font-size: 11px
    line-height: 1.25
    color: var(--cd-accent, #5DADE2)
  .fc .lo
    font-size: 11px
    line-height: 1.25
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

  .rings
    display: block
    width: 100%
    height: 55px
  .rings circle
    fill: none
    stroke-width: 4
    stroke-linecap: round
  .rings .bg
    opacity: 0.22
  .r-cpu
    stroke: var(--cd-accent, #5DADE2)
  .r-mem
    stroke: var(--cd-mid, #85C1E9)
  .r-disk
    stroke: var(--cd-deep, #2874A6)
  // La percentuale sta dentro il suo anello: e' il numero che l'anello
  // disegna, e tenerlo altrove obbligava a rileggere due volte.
  .rings .pct
    font-family: 'CDAbel', sans-serif
    font-size: 12px
    font-weight: 700
    fill: var(--cd-accent, #5DADE2)
    text-anchor: middle
  .syslabels
    display: grid
    grid-template-columns: repeat(3, 1fr)
    text-align: center
    margin-top: 4.4px
  .syslabels .k
    font-size: 9.4px
    letter-spacing: 1px
    opacity: 0.5
  .syslabels .v
    font-size: 11.6px
    line-height: 1.3
    color: var(--cd-mid, #85C1E9)

  .grid2
    display: grid
    grid-template-columns: 1fr 1fr
    column-gap: 13.2px
  .trow
    display: flex
    align-items: baseline
    gap: 6.6px
    margin-bottom: 4.4px
  .trow .k
    width: 24.2px
    flex: 0 0 auto
    font-size: 9.9px
    letter-spacing: 0.6px
    opacity: 0.6
  .trow .bar
    flex: 1 1 auto
    align-self: center
    height: 4.4px
    border-radius: 2.2px
    background: var(--cd-track, rgba(31,58,95,0.55))
    overflow: hidden
  .trow .bar i
    display: block
    height: 100%
    width: 0
    border-radius: 2.2px
    background: var(--cd-accent, #5DADE2)
    transition: width 0.45s ease-out, background-color 0.45s
  .trow.hot .bar i
    background: var(--cd-bright, #AED6F1)
  .trow .v
    width: 44px
    flex: 0 0 auto
    text-align: right
    font-size: 11.6px
    color: var(--cd-accent, #5DADE2)
  .pw
    display: grid
    grid-template-columns: repeat(3, 1fr)
  .pw .l
    font-size: 8.8px
    letter-spacing: 0.8px
    opacity: 0.45
  .pw .n
    font-size: 11.6px
    line-height: 1.25
    color: var(--cd-mid, #85C1E9)

  .netrow
    display: flex
    align-items: center
    gap: 8.8px
    margin-bottom: 2.2px
  .netrow .k
    width: 72.6px
    flex: 0 0 auto
    font-size: 11.6px
  .netrow .k .gly
    font-size: 9.9px
    margin-right: 4.4px
  .netrow .sp
    flex: 1 1 auto
    height: 16.5px
  .netrow .sp svg
    width: 100%
    height: 16.5px
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
    font-size: 11px
    line-height: 1.4
    padding: 0 5.5px
    border-radius: 3.3px
    overflow: hidden
  .prow .fill
    position: absolute
    top: 0
    bottom: 0
    left: 0
    width: 0
    border-radius: 3.3px
    background: var(--cd-fill, rgba(93,173,226,0.18))
    transition: width 0.4s ease-out
  .prow .n
    position: relative
    overflow: hidden
    white-space: nowrap
    text-overflow: ellipsis
    padding-right: 6.6px
  .prow .p
    position: relative
    flex: 0 0 auto
    color: var(--cd-accent, #5DADE2)

  // Le due quote stanno una per riga, come i sensori: affiancate su una riga
  // sola restavano due barrette da trenta punti e dei numeri da nove, che a
  // schermo non si leggevano. Qui la barra prende tutta la larghezza e il
  // numero ha la stessa taglia degli altri valori della card.
  .cc
    display: flex
    flex-direction: column
    gap: 5.5px
  .cc .q
    display: flex
    align-items: center
    gap: 6.6px
  .cc .q b
    width: 33px
    flex: 0 0 auto
    font-weight: 400
    font-size: 9.9px
    letter-spacing: 0.6px
    opacity: 0.6
  .cc .mini
    flex: 1 1 auto
    height: 6.6px
    border-radius: 3.3px
    background: var(--cd-track, rgba(31,58,95,0.55))
    overflow: hidden
  .cc .mini i
    display: block
    height: 100%
    width: 0
    border-radius: 3.3px
    background: var(--cd-accent, #5DADE2)
    transition: width 0.45s ease-out
  .cc .v
    width: 44px
    flex: 0 0 auto
    text-align: right
    font-size: 13.2px
    color: var(--cd-accent, #5DADE2)

  .cal-hdr
    display: flex
    align-items: center
    font-size: 13.2px
    font-weight: 700
    color: var(--cd-accent, #5DADE2)
    margin-bottom: 6.6px
  .cal-hdr .mo
    overflow: hidden
    white-space: nowrap
    text-overflow: ellipsis
  .cal-hdr .td
    flex: 0 0 auto
    margin-left: auto
    padding: 0 4.4px
    font-size: 9.9px
    font-weight: 400
    letter-spacing: 0.4px
    color: var(--cd-bright, #AED6F1)
    opacity: 0.6
    border-radius: 4.4px
  .cal-hdr .td.btn
    cursor: pointer
    opacity: 0.85
  .cal-hdr .td.btn:hover
    opacity: 1
    background: var(--cd-fill, rgba(93,173,226,0.18))
  .cal-hdr .nav
    flex: 0 0 auto
    width: 15.4px
    text-align: center
    font-size: 16.5px
    line-height: 16.5px
    color: var(--cd-bright, #AED6F1)
    opacity: 0.45
    border-radius: 4.4px
    cursor: pointer
    transition: opacity 0.15s, background 0.15s
  .cal-hdr .nav:hover
    opacity: 1
    background: var(--cd-fill, rgba(93,173,226,0.18))
  .grid
    display: grid
    grid-template-columns: 18.7px repeat(7, 1fr)
    row-gap: 1px
  .dow
    font-size: 8.8px
    letter-spacing: 0.4px
    text-align: center
    color: var(--cd-bright, #AED6F1)
    opacity: 0.5
    padding-bottom: 3.3px
    border-bottom: 1px solid var(--cd-rule, rgba(93,173,226,0.14))
    margin-bottom: 3.3px
  .cw
    height: 20.9px
    line-height: 20.9px
    text-align: center
    font-size: 9.4px
    color: var(--cd-bright, #AED6F1)
    opacity: 0.3
    border-right: 1px solid var(--cd-rule-faint, rgba(93,173,226,0.12))
  .dow.cw
    height: auto
    line-height: normal
    opacity: 0.3
  .cell
    height: 20.9px
    line-height: 20.9px
    text-align: center
    font-size: 11.6px
    border-radius: 5.5px
    cursor: pointer
    transition: background 0.15s
  .cell.we
    color: var(--cd-mid, #85C1E9)
  .cell.out
    opacity: 0.22
  .cell:hover
    background: var(--cd-fill, rgba(93,173,226,0.18))
  .cell.today
    background: var(--cd-accent, #5DADE2)
    color: var(--cd-ink, #0F1722)
    font-weight: 700
  .cell.today:hover
    background: var(--cd-mid, #85C1E9)
"""

render: -> """
  <style>
    @font-face{font-family:'CDAbel';src:url('cosmoduck-all.widget/fonts/Abel-Regular.ttf') format('truetype');}
    @font-face{font-family:'CDBebas';src:url('cosmoduck-all.widget/fonts/BebasNeue-Regular.ttf') format('truetype');}
    @font-face{font-family:'CDFeather';src:url('cosmoduck-all.widget/fonts/feather.ttf') format('truetype');}
  </style>
  <div class="lock-btn" id="lock-toggle"></div>

  <div class="sec"><span>WEATHER</span></div>
  <div class="wx">
    <div class="now">
      <span class="ico" id="a-wicon"></span>
      <span class="t" id="a-wtemp">--°</span>
    </div>
    <div class="mm">
      <div><span class="g" id="a-gmax"></span><span id="a-wmax">--</span></div>
      <div><span class="g" id="a-gmin"></span><span id="a-wmin">--</span></div>
    </div>
    <div class="city" id="a-city">—</div>
    <div class="wind"><span class="gly" id="a-gwind"></span><span id="a-wind">--</span></div>
    <div class="hum"><span class="gly" id="a-ghum"></span><span id="a-hum">--</span></div>
  </div>
  <div class="fc" id="a-fc"></div>

  <div class="rule"></div>
  <div class="sec"><span>SYSTEM</span><span class="st">FREE</span></div>
  <svg class="rings" viewBox="0 0 186 50">
    <circle class="bg r-cpu"  cx="31" cy="25" r="20"></circle>
    <circle class="fg r-cpu"  id="a-ring-cpu"  cx="31" cy="25" r="20" stroke-dasharray="0 125.66" transform="rotate(-90 31 25)"></circle>
    <text class="pct" x="31" y="29" id="a-pcpu">--</text>
    <circle class="bg r-mem"  cx="93" cy="25" r="20"></circle>
    <circle class="fg r-mem"  id="a-ring-mem"  cx="93" cy="25" r="20" stroke-dasharray="0 125.66" transform="rotate(-90 93 25)"></circle>
    <text class="pct" x="93" y="29" id="a-pmem">--</text>
    <circle class="bg r-disk" cx="155" cy="25" r="20"></circle>
    <circle class="fg r-disk" id="a-ring-disk" cx="155" cy="25" r="20" stroke-dasharray="0 125.66" transform="rotate(-90 155 25)"></circle>
    <text class="pct" x="155" y="29" id="a-pdisk">--</text>
  </svg>
  <div class="syslabels">
    <div><div class="k">CPU</div><div class="v">&nbsp;</div></div>
    <div><div class="k">RAM</div><div class="v" id="a-ramfree">--</div></div>
    <div><div class="k">DISK</div><div class="v" id="a-diskfree">--</div></div>
  </div>

  <div class="rule"></div>
  <div class="sec"><span>SENSORS</span><span class="st" id="a-battst"></span></div>
  <div class="trow" id="a-row-cpu"><span class="k">CPU</span><span class="bar"><i id="a-bar-cpu"></i></span><span class="v" id="a-cputemp">--</span></div>
  <div class="trow" id="a-row-gpu"><span class="k">GPU</span><span class="bar"><i id="a-bar-gpu"></i></span><span class="v" id="a-gputemp">--</span></div>
  <div class="trow" id="a-row-bat"><span class="k">BAT</span><span class="bar"><i id="a-bar-bat"></i></span><span class="v" id="a-battpct">--</span></div>
  <div class="pw">
    <div><div class="l">CPU W</div><div class="n" id="a-cpupwr">--</div></div>
    <div><div class="l">GPU W</div><div class="n" id="a-gpupwr">--</div></div>
    <div><div class="l">SYS W</div><div class="n" id="a-syspwr">--</div></div>
  </div>

  <div class="rule"></div>
  <div class="sec"><span>NETWORK</span><span class="st" id="a-ssid">—</span></div>
  <div class="netrow"><span class="k"><span class="gly" id="a-gdown"></span><span id="a-down">--</span></span><span class="sp" id="a-spdown"></span></div>
  <div class="netrow"><span class="k"><span class="gly" id="a-gup"></span><span id="a-up">--</span></span><span class="sp" id="a-spup"></span></div>

  <div class="rule"></div>
  <div class="sec"><span>CPU</span><span class="st">%</span></div>
  <div class="prow"><span class="fill" id="a-cf0"></span><span class="n" id="a-cn0"></span><span class="p" id="a-cp0"></span></div>
  <div class="prow"><span class="fill" id="a-cf1"></span><span class="n" id="a-cn1"></span><span class="p" id="a-cp1"></span></div>
  <div class="prow"><span class="fill" id="a-cf2"></span><span class="n" id="a-cn2"></span><span class="p" id="a-cp2"></span></div>
  <div class="sec sec2"><span>MEMORY</span><span class="st">%</span></div>
  <div class="prow"><span class="fill" id="a-rf0"></span><span class="n" id="a-rn0"></span><span class="p" id="a-rp0"></span></div>
  <div class="prow"><span class="fill" id="a-rf1"></span><span class="n" id="a-rn1"></span><span class="p" id="a-rp1"></span></div>
  <div class="prow"><span class="fill" id="a-rf2"></span><span class="n" id="a-rn2"></span><span class="p" id="a-rp2"></span></div>

  <div class="rule"></div>
  <div class="sec"><span>CLAUDE</span><span class="st" id="a-ccmodel">—</span></div>
  <div class="cc">
    <span class="q"><b>SESS</b><span class="mini"><i id="a-ccsbar"></i></span><span class="v" id="a-ccs">--</span></span>
    <span class="q"><b>WEEK</b><span class="mini"><i id="a-ccwbar"></i></span><span class="v" id="a-ccw">--</span></span>
  </div>

  <div class="rule"></div>
  <div class="cal-hdr">
    <span class="mo" id="a-month">—</span>
    <span class="td" id="a-today"></span>
    <span class="nav" id="a-prev">&#8249;</span>
    <span class="nav" id="a-next">&#8250;</span>
  </div>
  <div class="grid" id="a-grid"></div>

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

  # ── calendario ──────────────────────────────────────────────────────────────
  # Stessa griglia della card dedicata: mese con oggi evidenziato, numero di
  # settimana ISO nella prima colonna, frecce per sfogliare e click su un giorno
  # per aprire Calendar su quella data. Il mese mostrato e' uno stato del widget
  # (offset in mesi) che il refresh ogni cinque secondi non deve azzerare.
  WEEK_START = 1
  MONTHS = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY',
            'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER']
  DOW = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA']
  offset = 0
  drawn = null
  pad = (n) -> if n < 10 then "0#{n}" else "#{n}"

  isoWeek = (date) ->
    thu = new Date(date.getFullYear(), date.getMonth(), date.getDate() + 3 - ((date.getDay() + 6) % 7))
    first = new Date(thu.getFullYear(), 0, 4)
    first.setDate(first.getDate() + 3 - ((first.getDay() + 6) % 7))
    1 + Math.round((thu - first) / 604800000)

  draw = (force) ->
    day = domEl.dataset.day
    return unless day
    key = "#{day}/#{offset}"
    return if drawn == key and not force
    drawn = key
    [y, m, d] = (parseInt(v, 10) for v in day.split('-'))
    view  = new Date(y, m - 1 + offset, 1)
    vy    = view.getFullYear()
    vm    = view.getMonth()
    lead  = (view.getDay() - WEEK_START + 7) % 7
    inMon = new Date(vy, vm + 1, 0).getDate()
    head = ["<div class='dow cw'>CW</div>"]
    head.push "<div class='dow'>#{DOW[(WEEK_START + i) % 7]}</div>" for i in [0...7]
    # Sempre 6 righe: l'altezza della card non deve ballare da un mese all'altro.
    cells = for i in [0...42]
      n    = i - lead + 1
      cell = new Date(vy, vm, n)
      cls  = ['cell']
      cls.push 'we' if ((WEEK_START + i % 7) % 7) in [0, 6]
      cls.push 'out' if n < 1 or n > inMon
      cls.push 'today' if cell.getFullYear() == y and cell.getMonth() == m - 1 and cell.getDate() == d
      iso = "#{cell.getFullYear()}-#{pad(cell.getMonth() + 1)}-#{pad(cell.getDate())}"
      # La riga porta il numero di settimana del proprio giovedi'.
      week = if i % 7 == 0
        thu = new Date(vy, vm, n + ((4 - WEEK_START + 7) % 7))
        "<div class='cw'>#{isoWeek(thu)}</div>"
      else
        ''
      week + "<div class='#{cls.join(' ')}' data-date='#{iso}'>#{cell.getDate()}</div>"
    $(domEl).find('#a-month').text("#{MONTHS[vm]} #{vy}")
    $(domEl).find('#a-today')
      .text(if offset == 0 then "#{DOW[new Date(y, m - 1, d).getDay()]} #{d}" else 'TODAY')
      .toggleClass('btn', offset != 0)
    $(domEl).find('#a-grid').html(head.join('') + cells.join(''))

  domEl.__draw = draw

  # `run` arriva da Übersicht sull'oggetto del widget (API legacy). Se un domani
  # sparisse, il click semplicemente non fa nulla invece di rompere il widget.
  shell = if typeof @run == 'function' then @run.bind(this) else null

  openCal = (iso) ->
    return unless shell and iso
    [y, m, d] = (parseInt(v, 10) for v in "#{iso}".split('-'))
    return if isNaN(y) or isNaN(m) or isNaN(d)
    # Il giorno si azzera PRIMA di cambiare mese: partendo dal 31 un mese piu'
    # corto traboccherebbe. Mezzogiorno per stare lontani dai salti d'ora legale.
    arg = (t) -> "-e '#{t}' "
    shell "osascript " +
      arg("set d to current date") + arg("set day of d to 1") +
      arg("set year of d to #{y}") + arg("set month of d to #{m}") +
      arg("set day of d to #{d}") + arg("set time of d to 12 * hours") +
      arg('tell application "Calendar" to activate') +
      arg('tell application "Calendar" to view calendar at d')

  isDragging = false
  hasMoved = false
  startX = 0
  startY = 0

  # Delegati: la griglia viene riscritta a ogni ridisegno, i suoi figli no.
  # `hasMoved` distingue il click dal trascinamento partito sopra una cella.
  $(domEl).on 'click', '#a-prev', (e) ->
    e.stopPropagation()
    return if hasMoved
    offset -= 1
    draw(true)

  $(domEl).on 'click', '#a-next', (e) ->
    e.stopPropagation()
    return if hasMoved
    offset += 1
    draw(true)

  $(domEl).on 'click', '#a-today', (e) ->
    e.stopPropagation()
    return if hasMoved or offset == 0
    offset = 0
    draw(true)

  $(domEl).on 'click', '.cell', (e) ->
    e.stopPropagation()
    return if hasMoved
    openCal($(e.currentTarget).attr('data-date'))

  $(domEl).on 'mousedown', (e) ->
    return if isLocked or $(e.target).closest('.lock-btn').length
    hasMoved = false
    isDragging = true
    $(domEl).addClass('dragging')
    domEl.style.cursor = 'grabbing'
    startX = e.clientX - domEl.offsetLeft
    startY = e.clientY - domEl.offsetTop
    $(document).on 'mousemove', mouseMoveHandler
    $(document).on 'mouseup', mouseUpHandler

  mouseMoveHandler = (e) ->
    if isDragging
      hasMoved = true
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
    $el.find('#a-city').text(w.name or '—')
    $el.find('#a-gwind').text(ch(WIND))
    $el.find('#a-ghum').text(ch(DROP))
    $el.find('#a-wind').text("#{Math.round(w.wind.speed * 10) / 10} m/s")
    $el.find('#a-hum').text("#{w.main.humidity}%")
    today = wx.today or { min: Math.round(w.main.temp), max: Math.round(w.main.temp) }
    $el.find('#a-gmax').text(ch(UP))
    $el.find('#a-gmin').text(ch(DOWN))
    $el.find('#a-wmax').text("#{today.max}°")
    $el.find('#a-wmin').text("#{today.min}°")
    days = for day in (wx.forecast or [])
      """<div><div class="d">#{day.dow}</div><div class="i">#{glyph(day.icon)}</div>""" +
      """<div class="hi">#{day.max}°</div><div class="lo">#{day.min}°</div></div>"""
    $el.find('#a-fc').html(days.join(''))

  # ── sistema ────────────────────────────────────────────────────────────────
  sys = d.sys
  if sys
    ring = (id, pct) ->
      f = Math.max(0, Math.min(100, pct or 0)) / 100
      $el.find(id).attr('stroke-dasharray', "#{(f * 125.66).toFixed(2)} 125.66")
    ring('#a-ring-cpu', sys.cpu)
    ring('#a-ring-mem', sys.mem)
    ring('#a-ring-disk', sys.diskData)
    $el.find('#a-pcpu').text("#{sys.cpu}%")
    $el.find('#a-pmem').text("#{sys.mem}%")
    $el.find('#a-pdisk').text("#{sys.diskData}%")
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

  # ── calendario ─────────────────────────────────────────────────────────────
  if /^\d{4}-\d{2}-\d{2}$/.test(d.day or '')
    domEl.dataset.day = d.day
    domEl.__draw?()

  # ── Claude ─────────────────────────────────────────────────────────────────
  cc = d.cc
  if cc
    $el.find('#a-ccmodel').text((cc.model or '').toUpperCase())
    for [q, bar, val] in [[cc.session, '#a-ccsbar', '#a-ccs'], [cc.week, '#a-ccwbar', '#a-ccw']]
      continue unless q
      $el.find(bar).css('width', "#{Math.max(0, Math.min(100, q.pct or 0))}%")
      $el.find(val).text("#{q.pct}%")
  return
