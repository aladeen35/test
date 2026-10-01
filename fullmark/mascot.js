/* فول مارك — host mascot (inline SVG). Usage: Mascot.svg('point',{dir:'left'}) */
(function () {
  'use strict';
  var O = '#3A2416', SW = 3, SKIN = '#A86E47', SKIN_SH = '#8C5835', HAIR = '#1E1611',
    BEARD = '#1F1712', SHIRT = '#56585D', SHIRT_SH = '#47494E', CREAM = '#EDE6D3',
    YEL = '#E9D88A', TEE = '#18181A', JEAN = '#2F3237', JEAN_SH = '#25272B', SHOE = '#2A1C14',
    LIP = '#94503E', GRID = '#B8B09C';
  var uid = 0;

  function n(v) { return Math.round(v * 10) / 10; }
  function seg(p, w, c, cap) {
    return '<path d="M' + n(p[0]) + ' ' + n(p[1]) + 'L' + n(p[2]) + ' ' + n(p[3]) + '" stroke="' + c +
      '" stroke-width="' + n(w) + '" stroke-linecap="' + (cap || 'round') + '" fill="none"/>';
  }
  /* capsules [x1,y1,x2,y2,w] merged under one outline */
  function blob(parts, fill) {
    var o = '', f = '';
    for (var i = 0; i < parts.length; i++) { o += seg(parts[i], parts[i][4] + SW * 2, O); f += seg(parts[i], parts[i][4], fill); }
    return o + f;
  }
  function P(d, fill, sw, extra) {
    return '<path d="' + d + '" fill="' + (fill || 'none') + '" stroke="' + O + '" stroke-width="' + (sw == null ? SW : sw) +
      '" stroke-linejoin="round" stroke-linecap="round"' + (extra || '') + '/>';
  }
  function L(d, c, w) { return '<path d="' + d + '" fill="none" stroke="' + (c || O) + '" stroke-width="' + (w || 2) + '" stroke-linecap="round"/>'; }

  /* ---------- hands (local: wrist at 0,0, fingers toward +x, thumb toward -y) ---------- */
  var HANDS = {
    open: function () {
      return blob([[2, 0, 9, 0, 17], [11, -6, 23, -11.5, 5.5], [12, -2, 27.5, -4, 5.5], [12, 2, 26.5, 4, 5.5],
        [11, 6, 22, 10, 5], [4, -7, 10, -16, 6]], SKIN) + L('M4 4Q8 6 11 3', SKIN_SH, 1.5);
    },
    rest: function () {
      return blob([[2, 0, 10, 0, 17], [11, -5, 21, -6, 5.5], [12, -1.5, 23, -2, 5.5], [12, 2, 22, 2.5, 5.5], [11, 5.5, 19, 6.5, 5],
        [4, -7, 12, -11, 6]], SKIN) + L('M19 -3.5Q22 -2 20 0M19 0.5Q22 2 20 4', O, 1.2);
    },
    fist: function () {
      return blob([[1, 0, 11, 0, 19]], SKIN) + L('M15 -5L19 -5M15 0L19.5 0M15 5L19 5', O, 1.6) +
        blob([[5, -7, 13, -3, 6]], SKIN);
    },
    point: function () {
      return blob([[1, 0, 10, 0, 18], [10, -5, 31, -6, 6]], SKIN) + L('M14 0L18 1M13 5L17 6', O, 1.6) +
        blob([[4, -7, 12, -3, 6]], SKIN);
    },
    thumb: function () {
      return blob([[0, 0, 10, 0, 20], [6, -9, 5, -23, 8]], SKIN) + L('M7 -3.5L15 -3.5M7 1.5L15 1.5M7 6L14 6', O, 1.6);
    },
    mic: function () {
      return '<g transform="rotate(-90 12 0)">' +
        blob([[-6, 0, 26, 0, 7]], '#2B2B30') + blob([[26, 0, 29, 0, 10]], '#C9A24A') +
        blob([[37, 0, 37, 0, 18]], '#9AA0A8') + L('M31 -4L43 4M31 4L43 -4M37 -8.5L37 8.5', '#6C727B', 1.3) +
        '<circle cx="34" cy="-4" r="2" fill="#fff" opacity=".6"/></g>' +
        blob([[1, 0, 11, 0, 19]], SKIN) + L('M15 -5L19 -5M15 0L19.5 0M15 5L19 5', O, 1.6) +
        blob([[5, -7, 13, -3, 6]], SKIN);
    }
  };
  function hand(t, x, y, a, m) {
    return '<g transform="translate(' + n(x) + ' ' + n(y) + ') rotate(' + a + ') scale(1.25 ' + 1.25 * (m || 1) + ')">' + HANDS[t]() + '</g>';
  }

  /* ---------- arm: s shoulder, e elbow, w wrist ---------- */
  function band(e, ux, uy, len, w, fill) {
    var nx = -uy * w / 2, ny = ux * w / 2, bx = e[0] + ux * len, by = e[1] + uy * len;
    return P('M' + n(e[0] + nx) + ' ' + n(e[1] + ny) + 'L' + n(bx + nx) + ' ' + n(by + ny) + 'L' + n(bx - nx) + ' ' + n(by - ny) +
      'L' + n(e[0] - nx) + ' ' + n(e[1] - ny) + 'Z', fill, 2.6) + L('M' + n(e[0] + ux * len / 2 + nx * .8) + ' ' + n(e[1] + uy * len / 2 + ny * .8) +
      'L' + n(e[0] + ux * len / 2 - nx * .8) + ' ' + n(e[1] + uy * len / 2 - ny * .8), fill === CREAM ? GRID : SHIRT_SH, 1.4);
  }
  function arm(a, patched) {
    var s = a[0], e = a[1], w = a[2];
    var dx = w[0] - e[0], dy = w[1] - e[1], len = Math.sqrt(dx * dx + dy * dy) || 1, ux = dx / len, uy = dy / len;
    var mid = [s[0] + (e[0] - s[0]) * .55, s[1] + (e[1] - s[1]) * .55];
    var out = blob([[e[0], e[1], w[0], w[1], 15]], SKIN);
    out += blob([[s[0], s[1], e[0], e[1], 22]], SHIRT);
    if (patched) out += seg([mid[0], mid[1], e[0], e[1]], 22, CREAM, 'butt');
    out += band([e[0] - ux * 5, e[1] - uy * 5], ux, uy, 12, 26, patched ? CREAM : SHIRT);
    return out + hand(a[3], w[0], w[1], a[4], a[5]);
  }

  /* ---------- body ---------- */
  function legs() {
    return P('M76 250L164 250L162 338L124 338L121.5 282L118.5 282L116 338L78 338Z', JEAN) +
      L('M100 290L101 334M140 290L139 334', JEAN_SH, 2) +
      P('M76 340Q78 332 98 333Q118 334 118 344Q118 352 98 352Q74 352 76 340Z', SHOE) +
      P('M164 340Q162 332 142 333Q122 334 122 344Q122 352 142 352Q166 352 164 340Z', SHOE);
  }
  function torso(id) {
    var d = 'M94 138Q120 132 146 138L166 148Q176 154 174 172L170 262Q120 271 70 262L66 172Q64 154 74 148Z';
    var g = '<defs><clipPath id="' + id + 't"><path d="' + d + '"/></clipPath></defs>';
    g += '<path d="' + d + '" fill="' + SHIRT + '"/>';
    g += '<g clip-path="url(#' + id + 't)">' +
      '<path d="M150 150L176 150L176 270L150 270Z" fill="' + SHIRT_SH + '"/>' +
      '<path d="M60 222L98 222L98 214L120 214L120 206L180 206L180 280L60 280Z" fill="' + CREAM + '"/>' +
      '<path d="M138 160L164 158L165 204L139 205Z" fill="' + CREAM + '"/>' +
      '<path d="M127 206L156 206L156 222L127 222Z" fill="' + YEL + '"/>' +
      '<path d="M141 184L160 185L160 198L142 199Z" fill="' + YEL + '" opacity=".75"/>' +
      '<path d="M80 214L90 214L90 232L80 232Z" fill="' + YEL + '" opacity=".8"/>' +
      L('M60 186L180 184M60 242L180 244M100 150L101 268M150 150L149 268M140 172L165 171M60 168L94 167', GRID, 0.8) +
      L('M146 162L160 194M104 230L132 252', GRID, 0.7) + '</g>';
    g += P(d, 'none');
    g += L('M120 150L120 266', O, 1.6);
    for (var y = 164; y < 260; y += 24) g += '<circle cx="124" cy="' + y + '" r="2" fill="#3a3a3e" stroke="' + O + '" stroke-width=".8"/>';
    g += P('M104 132Q120 162 136 132Z', TEE, 2.5);
    g += P('M104 130L121 152L98 160L92 140Z', SHIRT, 2.5) + P('M136 130L119 152L142 160L148 140Z', SHIRT, 2.5);
    return g;
  }

  /* ---------- head ---------- */
  var BROWS = {
    n: ['M88 71Q99 65 111 69', 'M129 69Q141 65 152 71'],
    up: ['M88 68Q99 61 111 64', 'M129 64Q141 61 152 68'],
    worry: ['M89 70Q100 66 111 61', 'M129 61Q140 66 151 70'],
    think: ['M88 72Q99 69 111 71', 'M129 64Q141 57 152 63']
  };
  var MOUTHS = {
    smile: P('M104 115Q120 128 136 115Q120 121 104 115Z', LIP, 1.6),
    big: P('M100 112Q120 136 140 112Q120 117 100 112Z', '#5A1E18', 1.8) + P('M103 113.5Q120 118 137 113.5L135 118Q120 121 105 118Z', '#fff', 1),
    open: P('M103 111Q120 144 137 111Q120 115 103 111Z', '#5A1E18', 1.8) + '<path d="M110 128Q120 122 130 128Q125 136 120 136Q114 136 110 128Z" fill="#C8604E"/>' +
      P('M105 112.5Q120 116 135 112.5L134 117Q120 119 106 117Z', '#fff', 1),
    hmm: P('M111 118Q121 115 132 119Q121 121 111 118Z', LIP, 1.6),
    sheep: P('M104 116Q112 112 120 116Q128 112 137 115Q130 125 120 124Q110 125 104 116Z', '#fff', 1.6) + L('M120 116L120 124M112 115L112 123M128 115L128 123', '#c9bfb0', 1)
  };
  function eye(cx, cy, lx, ly, kind) {
    if (kind === 'happy') return L('M' + (cx - 8) + ' ' + (cy + 2) + 'Q' + cx + ' ' + (cy - 7) + ' ' + (cx + 8) + ' ' + (cy + 2), O, 3);
    var g = '<ellipse cx="' + cx + '" cy="' + cy + '" rx="8.5" ry="7.5" fill="#fff" stroke="' + O + '" stroke-width="2"/>' +
      '<circle cx="' + (cx + lx) + '" cy="' + (cy + ly) + '" r="5.2" fill="#4A2A18"/>' +
      '<circle cx="' + (cx + lx) + '" cy="' + (cy + ly) + '" r="2.6" fill="#120A06"/>' +
      '<circle cx="' + (cx + lx + 1.8) + '" cy="' + (cy + ly - 2) + '" r="1.6" fill="#fff"/>' +
      L('M' + (cx - 9.5) + ' ' + (cy - 1) + 'Q' + cx + ' ' + (cy - 10) + ' ' + (cx + 9.5) + ' ' + (cy - 1), O, 3);
    if (kind === 'squint') g += L('M' + (cx - 7) + ' ' + (cy + 6) + 'Q' + cx + ' ' + (cy + 3) + ' ' + (cx + 7) + ' ' + (cy + 6), SKIN_SH, 2);
    return g;
  }
  function hair() {
    var o = '', f = '', tx = '', i, a, x, y;
    var cap = 'M71 84C65 44 88 23 120 23C152 23 175 44 169 84L162 84C160 66 154 58 147 55Q120 47 93 55C86 58 80 66 78 84Z';
    for (i = 0; i <= 12; i++) {
      a = Math.PI * (1.02 + i * 0.08);
      x = 120 + Math.cos(a) * 46; y = 58 + Math.sin(a) * 32;
      o += seg([x, y, x, y], 14 + SW * 2, O);
      f += seg([x, y, x, y], 14, HAIR);
      if (i % 2 === 0 && i > 0 && i < 12) tx += 'M' + n(x - 3) + ' ' + n(y + 3) + 'q3 -5 6 0';
    }
    tx += 'M98 42q3-4 6 0M112 36q3-4 6 0M126 42q3-4 6 0M140 37q3-4 6 0M104 48q3-4 6 0M134 48q3-4 6 0M120 46q3-4 6 0';
    return P(cap, HAIR, SW * 2) + o + f +
      '<path d="' + cap + '" fill="' + HAIR + '"/>' + L(tx, '#3B2C22', 1.6);
  }
  function head(id, f) {
    var g = '';
    g += '<rect x="107" y="118" width="26" height="24" fill="' + SKIN_SH + '" stroke="' + O + '" stroke-width="' + SW + '"/>';
    g += P('M71 76Q60 78 62 90Q64 101 75 101Z', SKIN) + P('M169 76Q180 78 178 90Q176 101 165 101Z', SKIN);
    g += L('M70 84Q66 88 70 94M170 84Q174 88 170 94', SKIN_SH, 2);
    var face = 'M72 80C72 40 168 40 168 80C168 116 150 142 120 142C90 142 72 116 72 80Z';
    g += '<defs><clipPath id="' + id + 'f"><path d="' + face + '"/></clipPath></defs>';
    g += '<path d="' + face + '" fill="' + SKIN + '"/>';
    g += '<g clip-path="url(#' + id + 'f)"><circle cx="100" cy="76" r="62" fill="' + SKIN_SH + '" opacity="0"/>' +
      '<path d="M150 50Q166 80 152 120L180 120L180 50Z" fill="' + SKIN_SH + '" opacity=".55"/></g>';
    g += P(face, 'none');
    g += '<ellipse cx="91" cy="99" rx="8" ry="5" fill="#C9725A" opacity=".35"/><ellipse cx="149" cy="99" rx="8" ry="5" fill="#C9725A" opacity=".35"/>';
    /* beard */
    g += P('M71 80C71 116 88 148 120 148C152 148 169 116 169 80L161 82C160 96 154 104 147 106C139 101 129 101 120 103C111 101 101 101 93 106C86 104 80 96 79 82Z', BEARD, SW);
    g += L('M84 112q2 3 4 1M152 112q2 3 4 1M96 130q2 3 4 1M140 130q2 3 4 1M118 140q2 3 4 1', '#3A2C22', 1.4);
    g += MOUTHS[f.m];
    g += P('M97 110Q108 101 120 106Q132 101 143 110Q132 114 120 111Q108 114 97 110Z', BEARD, 1.5);
    /* nose */
    g += L('M117 84Q115 92 112 96', SKIN_SH, 2) + P('M110 95Q106 101 113 102Q120 105 127 102Q134 101 130 95', 'none', 2.2) +
      '<path d="M114 99.5q2 1 4 0M122 99.5q2 1 4 0" stroke="' + O + '" stroke-width="1.6" fill="none" stroke-linecap="round"/>';
    g += eye(100, 82, f.lx || 0, f.ly || 0, f.e) + eye(140, 82, f.lx || 0, f.ly || 0, f.e);
    var b = BROWS[f.b];
    g += L(b[0], HAIR, 5.5) + L(b[1], HAIR, 5.5);
    g += hair();
    return g;
  }

  /* ---------- poses: arm = [shoulder, elbow, wrist, hand, angle, mirror]; R = viewer-left ---------- */
  var S_R = [80, 154], S_L = [160, 154];
  var POSES = {
    point: { R: [S_R, [50, 192], [72, 224], 'fist', 60, -1], L: [S_L, [197, 146], [226, 140], 'point', -8, 1], f: { m: 'smile', b: 'up', lx: 2.5 }, t: -30 },
    thumbs: { R: [S_R, [64, 204], [88, 176], 'thumb', 0, 1], L: [S_L, [176, 204], [152, 176], 'thumb', 180, -1], f: { m: 'big', b: 'up', e: 'squint' } },
    cheer: { R: [S_R, [48, 118], [36, 82], 'open', -100, -1], L: [S_L, [192, 118], [204, 82], 'open', -80, 1], f: { m: 'open', b: 'up', e: 'happy' } },
    think: { R: [S_R, [90, 206], [106, 172], 'fist', -72, 1], L: [S_L, [164, 208], [122, 210], 'fist', 180, -1], f: { m: 'hmm', b: 'think', lx: 3, ly: -3 } },
    oops: { R: [S_R, [70, 204], [72, 242], 'rest', 92, 1], L: [S_L, [196, 124], [172, 88], 'open', 218, -1], f: { m: 'sheep', b: 'worry', lx: -2, ly: 1 }, x: 'sweat' },
    wave: { R: [S_R, [70, 204], [72, 242], 'rest', 92, 1], L: [S_L, [196, 180], [206, 142], 'open', -78, 1], f: { m: 'smile', b: 'n' } },
    mic: { R: [S_R, [78, 210], [104, 180], 'mic', 0, 1], L: [S_L, [192, 198], [204, 174], 'open', -62, 1], f: { m: 'smile', b: 'up', lx: 1 } }
  };

  function svg(pose, opts) {
    opts = opts || {};
    var p = POSES[pose] || POSES.wave, id = 'fm' + (++uid) + '_';
    var body = legs() + torso(id) + head(id, p.f) + arm(p.R, false) + arm(p.L, true);
    if (p.x === 'sweat') body += P('M172 46Q178 56 176 60Q172 65 168 60Q166 56 172 46Z', '#9FD3F0', 2);
    if (p.t) body = '<g transform="translate(' + p.t + ' 0)">' + body + '</g>';
    if (pose === 'point' && opts.dir === 'left') body = '<g transform="matrix(-1 0 0 1 240 0)">' + body + '</g>';
    if (opts.rim) { /* light sticker edge for dark backgrounds */
      body = '<defs><filter id="' + id + 'r" x="-10%" y="-10%" width="120%" height="120%"><feMorphology in="SourceAlpha" operator="dilate" radius="2.5" result="d"/>' +
        '<feFlood flood-color="' + (opts.rim === true ? '#F6EBD5' : opts.rim) + '" flood-opacity=".9"/><feComposite operator="in" in2="d"/>' +
        '<feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs><g filter="url(#' + id + 'r)">' + body + '</g>';
    }
    var cls = opts.className ? ' class="' + opts.className + '"' : '';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 360" role="img" aria-labelledby="' + id + 'title"' + cls +
      (opts.width ? ' width="' + opts.width + '"' : '') + (opts.height ? ' height="' + opts.height + '"' : '') +
      '><title id="' + id + 'title">مقدّم فول مارك</title>' + body + '</svg>';
  }

  window.Mascot = { svg: svg, poses: Object.keys(POSES) };
})();
