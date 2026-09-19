# Cosmoduck · Tema — Übersicht (widget invisibile)
#
# Non disegna niente: legge il wallpaper in uso, ne ricava una palette e la
# pubblica come variabili CSS su <html>. Übersicht monta tutti i widget in un
# unico documento per schermo, quindi le variabili scritte qui arrivano a tutti
# gli altri senza che debbano saperne niente.
#
# Ogni colore nei widget e' scritto come `var(--cd-x, <colore originale>)`: se
# questo widget non c'e', fallisce o lo togli dalla cartella, il set torna da
# solo al blu Cosmoduck di sempre. La taratura (quanto il wallpaper detta il
# colore) sta in cima a scripts/collect.sh.
#
# Lo script di estrazione e' scripts/palette.jxa: l'estensione non e' .js
# perche' Ubersicht caricherebbe quel file come se fosse un widget.

command: "bash cosmoduck-theme.widget/scripts/collect.sh"
refreshFrequency: 30000

style: """
  display: none
"""

render: -> ""

update: (output, domEl) ->
  return unless output and output.trim()
  try
    data = JSON.parse(output)
  catch
    return                      # script a meta' o wallpaper illeggibile: si tiene la palette di prima
  return unless data and data.vars
  root = document.documentElement
  root.style.setProperty(name, value) for name, value of data.vars
  # Comoda per capire da dove viene la palette: leggila con
  #   document.documentElement.dataset.cosmoduckTheme
  root.dataset.cosmoduckTheme = "hue #{data.hue} · sat×#{data.satScale} · #{data.source}"
  return
