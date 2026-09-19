#!/usr/bin/env osascript -l JavaScript
// Cosmoduck · palette — estrae un accento dal wallpaper.
//
// Uso:  osascript -l JavaScript palette.js <file-url-o-path> <blend> <sat-floor>
// Stdout: un oggetto JSON di variabili CSS, o niente (exit 1) se l'immagine non
// si apre. Nessuna dipendenza: solo il bridge ObjC di JXA.
//
// Il tema originale e' una sola tinta (~204 deg) campionata a stop fissi di
// saturazione e luminosita' — vedi TEMA qui sotto. Quindi adattarlo al
// wallpaper vuol dire ruotare la tinta e riscalare la saturazione, tenendo la
// luminosita' dov'e': e' la L che decide se il testo si legge sul vetro scuro,
// e quella non la puo' dettare una foto.
ObjC.import('AppKit');
ObjC.import('stdlib');

// osascript -l JavaScript <script> a b c  ->  argv[0..3] sono l'interprete e i
// suoi flag; gli argomenti nostri cominciano al 4.
var ARGV = ObjC.deepUnwrap($.NSProcessInfo.processInfo.arguments).slice(4);

var SRC       = ARGV[0] || null;
var BLEND     = parseFloat(ARGV[1]); if (isNaN(BLEND))     BLEND = 1.0;
var SAT_FLOOR = parseFloat(ARGV[2]); if (isNaN(SAT_FLOOR)) SAT_FLOOR = 0.75;

var BASE_HUE = 204;          // la tinta Cosmoduck, usata come ancora e ripiego
var SAT_REF  = 0.35;         // saturazione del wallpaper che vale "scala 1.0"
var SAT_CAP  = 1.15;         // quanto puo' spingere un wallpaper molto acceso

// ruolo: [saturazione, luminosita', scarto di tinta] — misurati sui colori
// hardcoded originali, che non sono su una tinta sola: i tre toni scuri stanno
// una decina di gradi piu' in la', ed e' quello scarto a dargli il freddo.
var TEMA = {
  accent: [0.70, 0.63,  0],  // #5DADE2
  bright: [0.70, 0.81,  0],  // #AED6F1
  mid:    [0.70, 0.72,  0],  // #85C1E9
  deep:   [0.61, 0.40,  0],  // #2874A6
  shadow: [0.51, 0.25, 11],  // #1F3A5F
  text:   [0.41, 0.85,  4],  // #C8D9E8
  ink:    [0.39, 0.10, 11],  // #0F1722
  glass:  [0.36, 0.10,  8]   // rgba(16,24,34,.55)
};

function clamp(v, lo, hi) { return v < lo ? lo : v > hi ? hi : v; }

function rgbToHsl(r, g, b) {
  r /= 255; g /= 255; b /= 255;
  var mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, h = 0, s = 0;
  if (mx !== mn) {
    var d = mx - mn;
    s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
    h = mx === r ? (g - b) / d + (g < b ? 6 : 0) : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
    h *= 60;
  }
  return [h, s, l];
}

function hslToRgb(h, s, l) {
  h = ((h % 360) + 360) % 360;
  s = clamp(s, 0, 1); l = clamp(l, 0, 1);
  var a = s * Math.min(l, 1 - l);
  var f = function (n) {
    var k = (n + h / 30) % 12;
    return Math.round(255 * (l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1))));
  };
  return [f(0), f(8), f(4)];
}

function hex(rgb) {
  return '#' + rgb.map(function (v) { return v.toString(16).padStart(2, '0'); }).join('').toUpperCase();
}
function rgba(rgb, a) { return 'rgba(' + rgb[0] + ',' + rgb[1] + ',' + rgb[2] + ',' + a + ')'; }

// In JXA console.log finisce su stderr: Ubersicht legge stdout, quindi il JSON
// va scritto a mano sul file handle giusto.
function emit(handle, text) {
  handle.writeData($.NSString.alloc.initWithUTF8String(text)
    .dataUsingEncoding($.NSUTF8StringEncoding));
}
function out(text) { emit($.NSFileHandle.fileHandleWithStandardOutput, text + '\n'); }
function err(text) { emit($.NSFileHandle.fileHandleWithStandardError, text + '\n'); }

function loadRep(src) {
  var img = /^file:\/\//.test(src)
    ? $.NSImage.alloc.initWithContentsOfURL($.NSURL.URLWithString(src))
    : $.NSImage.alloc.initWithContentsOfFile(src);
  if (!img || !img.js || !img.isValid) return null;
  // Attraverso la TIFFRepresentation invece di disegnare in un contesto: il
  // wallpaper puo' essere HEIC, dinamico o multi-risoluzione, e qui prendiamo
  // comunque una rappresentazione bitmap gia' risolta.
  var rep = $.NSBitmapImageRep.imageRepWithData(img.TIFFRepresentation);
  return rep && rep.js ? rep : null;
}

// Tinta dominante: istogramma a 36 bin pesato sul quadrato della saturazione,
// cosi' una piccola zona accesa conta piu' di un grande fondo slavato — che e'
// esattamente come l'occhio sceglie "il colore" di una foto. Poi si media sul
// bin vincente piu' i due vicini, perche' il confine fra bin non deve far
// saltare l'accento di 10 gradi per un pixel.
function dominantHue(rep) {
  var W = rep.pixelsWide, H = rep.pixelsHigh, N = 48, BINS = 36;
  var w = new Array(BINS).fill(0), sh = new Array(BINS).fill(0), ss = new Array(BINS).fill(0);
  var ref = $.NSCalibratedRGBColorSpace, total = 0;
  for (var i = 0; i < N; i++) {
    for (var j = 0; j < N; j++) {
      var c = rep.colorAtXY(Math.floor((i + 0.5) * W / N), Math.floor((j + 0.5) * H / N));
      c = c.colorUsingColorSpaceName(ref);
      if (!c.js) continue;
      var hsl = rgbToHsl(c.redComponent * 255, c.greenComponent * 255, c.blueComponent * 255);
      if (hsl[2] < 0.10 || hsl[2] > 0.92 || hsl[1] < 0.10) continue;  // nero, bianco, grigio
      var k = Math.floor(hsl[0] / (360 / BINS)) % BINS;
      var weight = hsl[1] * hsl[1] * (1 - Math.abs(hsl[2] - 0.5) * 0.6);
      w[k] += weight; ss[k] += hsl[1] * weight; total += weight;
      // le tinte si mediano sul cerchio: sommare 359 e 1 in scalare da' 180
      sh[k] += weight * hsl[0] * Math.PI / 180;
    }
  }
  if (total < 0.5) return null;                      // wallpaper piatto o monocromo
  var best = 0;
  for (var b = 1; b < BINS; b++) if (w[b] > w[best]) best = b;
  var x = 0, y = 0, sat = 0, acc = 0;
  for (var d = -1; d <= 1; d++) {
    var k2 = (best + d + BINS) % BINS;
    if (!w[k2]) continue;
    var hk = sh[k2] / w[k2];
    x += Math.cos(hk) * w[k2]; y += Math.sin(hk) * w[k2];
    sat += ss[k2]; acc += w[k2];
  }
  if (!acc) return null;
  var hue = Math.atan2(y, x) * 180 / Math.PI;
  return { hue: ((hue % 360) + 360) % 360, sat: sat / acc };
}

// Miscela verso la tinta base lungo l'arco corto: con BLEND = 0.3 un wallpaper
// verde sposta il blu di qualche decina di gradi invece di sostituirlo.
function blendHue(from, to, t) {
  var d = ((to - from + 540) % 360) - 180;
  return ((from + d * t) % 360 + 360) % 360;
}

var rep = SRC ? loadRep(SRC) : null;
if (!rep) {
  // Niente stdout: chi ci chiama tiene la palette precedente, e i widget hanno
  // comunque il colore originale come fallback nel CSS.
  err('cosmoduck-theme: immagine non leggibile: ' + SRC);
  $.exit(1);
}

var dom = dominantHue(rep);
var hue = dom ? blendHue(BASE_HUE, dom.hue, clamp(BLEND, 0, 1)) : BASE_HUE;
var satScale = dom ? clamp(dom.sat / SAT_REF, SAT_FLOOR, SAT_CAP) : 1.0;
satScale = 1 + (satScale - 1) * clamp(BLEND, 0, 1);

var c = {};
Object.keys(TEMA).forEach(function (role) {
  c[role] = hslToRgb(hue + TEMA[role][2], clamp(TEMA[role][0] * satScale, 0.05, 0.95), TEMA[role][1]);
});

out(JSON.stringify({
  source: SRC,
  hue: Math.round(hue),
  wallpaperHue: dom ? Math.round(dom.hue) : null,
  wallpaperSat: dom ? +dom.sat.toFixed(3) : null,
  satScale: +satScale.toFixed(3),
  vars: {
    '--cd-accent':     hex(c.accent),
    '--cd-bright':     hex(c.bright),
    '--cd-mid':        hex(c.mid),
    '--cd-deep':       hex(c.deep),
    '--cd-shadow':     hex(c.shadow),
    '--cd-text':       hex(c.text),
    '--cd-ink':        hex(c.ink),
    '--cd-glass':      rgba(c.glass, 0.55),
    '--cd-border':     rgba(c.accent, 0.22),
    '--cd-fill':       rgba(c.accent, 0.18),
    '--cd-rule':       rgba(c.accent, 0.14),
    '--cd-rule-faint': rgba(c.accent, 0.12),
    '--cd-track':      rgba(c.shadow, 0.55)
  }
}));
