# Cosmoduck · Calendario — Übersicht (legacy, lockable & draggable)
# Mese a griglia con oggi evidenziato, frecce per sfogliare i mesi e click su un
# giorno per aprire Calendar di macOS su quella data.
#
# La data di "oggi" arriva da `date`, non da new Date() del browser: cosi' la
# griglia segue l'orologio di sistema anche se Übersicht resta aperto attraverso
# un cambio di giorno o di fuso. Il mese mostrato invece e' uno stato del widget
# (offset in mesi), che il refresh ogni minuto non deve azzerare.

command: "date +%Y-%m-%d"
refreshFrequency: 60000

style: """
  top: 310px
  left: 168px
  width: 216px
  height: 190px
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
  padding: 13px 14px 0 14px
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
    display: flex
    align-items: center
    font-size: 13px
    font-weight: 700
    color: var(--cd-accent, #5DADE2)
    margin-bottom: 8px
    padding-right: 15px
  .hdr svg
    width: 10px
    height: 10px
    margin-right: 5px
    flex: 0 0 auto
  .hdr .mo
    overflow: hidden
    white-space: nowrap
    text-overflow: ellipsis
  .hdr .td
    flex: 0 0 auto
    margin-left: auto
    padding: 0 4px
    font-size: 9px
    font-weight: 400
    letter-spacing: 0.4px
    color: var(--cd-bright, #AED6F1)
    opacity: 0.6
    border-radius: 4px
  .hdr .nav
    flex: 0 0 auto
    width: 14px
    text-align: center
    font-size: 15px
    line-height: 15px
    color: var(--cd-bright, #AED6F1)
    opacity: 0.45
    border-radius: 4px
    cursor: pointer
    transition: opacity 0.15s, background 0.15s
  .hdr .nav:hover
    opacity: 1
    background: var(--cd-fill, rgba(93,173,226,0.18))
  .hdr .td.btn
    cursor: pointer
    opacity: 0.85
  .hdr .td.btn:hover
    opacity: 1
    background: var(--cd-fill, rgba(93,173,226,0.18))

  .grid
    display: grid
    grid-template-columns: 19px repeat(7, 1fr)
    row-gap: 1px

  .dow
    font-size: 8px
    letter-spacing: 0.4px
    text-align: center
    color: var(--cd-bright, #AED6F1)
    opacity: 0.5
    padding-bottom: 4px
    border-bottom: 1px solid var(--cd-rule, rgba(93,173,226,0.14))
    margin-bottom: 3px

  .cw
    height: 20px
    line-height: 20px
    text-align: center
    font-size: 9px
    color: var(--cd-bright, #AED6F1)
    opacity: 0.3
    border-right: 1px solid var(--cd-rule-faint, rgba(93,173,226,0.12))
  .dow.cw
    height: auto
    line-height: normal
    opacity: 0.3

  .cell
    height: 20px
    line-height: 20px
    text-align: center
    font-size: 11px
    border-radius: 6px
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
  <style>@font-face{font-family:'CDAbel';src:url('cosmoduck-cal.widget/fonts/Abel-Regular.ttf') format('truetype');}</style>
  <div class="lock-btn" id="lock-toggle"></div>
  <div class="hdr">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="2"></rect><path d="M3 10h18M8 3v4M16 3v4"></path></svg>
    <span class="mo" id="month">--</span>
    <span class="td" id="today"></span>
    <span class="nav" id="prev">&#8249;</span>
    <span class="nav" id="next">&#8250;</span>
  </div>
  <div class="grid" id="grid"></div>
  <div class="pos-indicator" id="coords">T: 0 L: 0</div>
"""

afterRender: (domEl) ->
  P = "cosmoduck-cal"
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

  # ── calendario ───────────────────────────────────────────────────────────────
  # Primo giorno della settimana: 1 = lunedi', 0 = domenica.
  WEEK_START = 1
  MONTHS = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY',
            'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER']
  DOW = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA']

  offset = 0        # mesi di distanza dal mese corrente
  drawn  = null     # ultima griglia disegnata, per non ridisegnarla ogni minuto

  pad = (n) -> if n < 10 then "0#{n}" else "#{n}"

  # Settimana ISO 8601: a decidere numero e anno della settimana e' il suo
  # giovedi', non il giorno che si guarda. Ci si sposta li' e si contano i
  # sette-giorni dal giovedi' della settimana 1, che e' quella del 4 gennaio.
  # Round e non floor: due cambi d'ora legale in mezzo sfalsano di un'ora.
  isoWeek = (date) ->
    thu = new Date(date.getFullYear(), date.getMonth(), date.getDate())
    thu.setDate(thu.getDate() + 3 - ((thu.getDay() + 6) % 7))
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
    view  = new Date(y, m - 1 + offset, 1)   # l'offset traborda da solo negli anni
    vy    = view.getFullYear()
    vm    = view.getMonth()
    lead  = (view.getDay() - WEEK_START + 7) % 7
    inMon = new Date(vy, vm + 1, 0).getDate()

    head = ["<div class='dow cw'>CW</div>"]
    head.push "<div class='dow'>#{DOW[(WEEK_START + i) % 7]}</div>" for i in [0...7]

    # Sempre 6 righe: l'altezza della card non deve ballare da un mese all'altro.
    # I numeri fuori mese li normalizza Date: 0 = ultimo giorno del mese prima.
    cells = for i in [0...42]
      n    = i - lead + 1
      cell = new Date(vy, vm, n)
      cls  = ['cell']
      cls.push 'we' if ((WEEK_START + i % 7) % 7) in [0, 6]
      cls.push 'out' if n < 1 or n > inMon
      cls.push 'today' if cell.getFullYear() == y and cell.getMonth() == m - 1 and cell.getDate() == d
      iso = "#{cell.getFullYear()}-#{pad(cell.getMonth() + 1)}-#{pad(cell.getDate())}"
      # La riga porta il numero della settimana del proprio giovedi': cosi' il
      # conto resta giusto anche con WEEK_START = 0, dove la riga si apre di
      # domenica e la domenica appartiene ancora alla settimana ISO precedente.
      week = if i % 7 == 0
        thu = new Date(vy, vm, n + ((4 - WEEK_START + 7) % 7))
        "<div class='cw'>#{isoWeek(thu)}</div>"
      else
        ''
      week + "<div class='#{cls.join(' ')}' data-date='#{iso}'>#{cell.getDate()}</div>"

    $(domEl).find('#month').text("#{MONTHS[vm]} #{vy}")
    $(domEl).find('#today')
      .text(if offset == 0 then "#{DOW[new Date(y, m - 1, d).getDay()]} #{d}" else 'TODAY')
      .toggleClass('btn', offset != 0)
    $(domEl).find('#grid').html(head.join('') + cells.join(''))

  domEl.__draw = draw

  # `run` arriva da Übersicht sull'oggetto del widget (API legacy). Se un domani
  # sparisse, il click semplicemente non fa nulla invece di rompere il widget.
  shell = if typeof @run == 'function' then @run.bind(this) else null

  openCal = (iso) ->
    return unless shell and iso
    [y, m, d] = (parseInt(v, 10) for v in "#{iso}".split('-'))
    return if isNaN(y) or isNaN(m) or isNaN(d)
    # Il giorno si azzera PRIMA di cambiare mese: partendo dal 31 un mese piu'
    # corto traboccherebbe (31 + febbraio = 3 marzo). Mezzogiorno per stare
    # lontani dai salti d'ora legale. Una riga per -e: niente da quotare a mano.
    arg = (s) -> "-e '#{s}' "
    shell "osascript " +
      arg("set d to current date") + arg("set day of d to 1") +
      arg("set year of d to #{y}") + arg("set month of d to #{m}") +
      arg("set day of d to #{d}") + arg("set time of d to 12 * hours") +
      arg('tell application "Calendar" to activate') +
      arg('tell application "Calendar" to view calendar at d')

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
  hasMoved = false
  startX = 0
  startY = 0

  # Delegati: la griglia viene riscritta a ogni ridisegno, i suoi figli no.
  # `hasMoved` distingue il click dal trascinamento partito sopra una cella.
  $(domEl).on 'click', '#prev', (e) ->
    e.stopPropagation()
    return if hasMoved
    offset -= 1
    draw(true)

  $(domEl).on 'click', '#next', (e) ->
    e.stopPropagation()
    return if hasMoved
    offset += 1
    draw(true)

  $(domEl).on 'click', '#today', (e) ->
    e.stopPropagation()
    return if hasMoved or offset == 0
    offset = 0
    draw(true)

  # Doppio click, non singolo: aprire Calendar e' un'azione che porta un'app in
  # primo piano, troppo facile da innescare per sbaglio passando sulla griglia.
  $(domEl).on 'dblclick', '.cell', (e) ->
    return if hasMoved
    openCal $(e.currentTarget).attr('data-date')

  $(domEl).on 'mousedown', (e) ->
    hasMoved = false
    return if isLocked or $(e.target).closest('.lock-btn, .nav, .td.btn').length
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

  draw()

update: (output, domEl) ->
  day = output.trim()
  return unless /^\d{4}-\d{2}-\d{2}$/.test(day)
  domEl.dataset.day = day
  domEl.__draw?()
