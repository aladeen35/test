// Parametric cartoon portrait generator for "أنا مِنو" characters.
// Produces consistent 1:1 SVG portraits from character metadata so the
// whole cast shares one art direction. Real illustrated artwork can later
// replace these files without touching game logic (same asset paths).

const SKIN = {
  light: { base: '#FFDCB8', shade: '#F3C393' },
  tan: { base: '#F0B98A', shade: '#DFA271' },
  medium: { base: '#C98A5B', shade: '#B27548' },
  dark: { base: '#8D5B3C', shade: '#7A4B2F' },
};

const HAIR = {
  black: '#2A2320',
  brown: '#6B4226',
  gray: '#9AA0A6',
  blonde: '#E3B94E',
  covered: '#2A2320',
};

const OUTLINE = '#26211E';

const HIJAB_COLORS = {
  'doctor-female': '#35577D',
  'teacher-female': '#7C5CBF',
  'farmer-female': '#D94F42',
  'pharmacist-female': '#173B6C',
};

const CASUAL_COLORS = {
  'programmer-male': '#2FBF9B',
  'programmer-female': '#7C5CBF',
  'photographer-male': '#4C6A92',
  'photographer-female': '#F5A800',
  'graphic-designer-male': '#F26B5E',
};

const BLAZER_COLORS = {
  'teacher-male': '#46628F',
  'teacher-female': '#3E8E7E',
  'architect-female': '#7C5CBF',
  'journalist-female': '#D94F42',
};

const OVERALL_SHIRT = {
  'farmer-male': '#C0392B',
  'farmer-female': '#3E8E7E',
  'electrician-male': '#F5A800',
  'mechanic-female': '#D94F42',
};

function el(tag, attrs = {}, children = '') {
  const a = Object.entries(attrs)
    .map(([k, v]) => `${k}="${v}"`)
    .join(' ');
  return children === '' && tag !== 'g'
    ? `<${tag} ${a}/>`
    : `<${tag} ${a}>${children}</${tag}>`;
}

function tint(hex, amount = 0.82) {
  // Mix color with white: amount = how much white.
  const n = parseInt(hex.slice(1), 16);
  const r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
  const mix = (c) => Math.round(c + (255 - c) * amount);
  return `#${[mix(r), mix(g), mix(b)].map((c) => c.toString(16).padStart(2, '0')).join('')}`;
}

function shade(hex, amount = 0.25) {
  const n = parseInt(hex.slice(1), 16);
  const r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
  const mix = (c) => Math.round(c * (1 - amount));
  return `#${[mix(r), mix(g), mix(b)].map((c) => c.toString(16).padStart(2, '0')).join('')}`;
}

/* ------------------------------ clothing ------------------------------ */

const TORSO = 'M38 242 C38 194 70 164 120 164 C170 164 202 194 202 242 Z';

function clothing(c) {
  const parts = [];
  const slug = c.slug;
  const torso = (fill) => el('path', { d: TORSO, fill });
  const shirtV = (fill) => el('path', { d: 'M98 166 L120 198 L142 166 Q120 158 98 166 Z', fill });

  switch (c.clothing) {
    case 'whiteCoat': {
      parts.push(torso('#F7F9FB'));
      parts.push(shirtV(tint(c.accent, 0.35)));
      parts.push(el('path', { d: 'M98 166 L112 186 L96 214 L84 172 Z', fill: '#E6EBF1' }));
      parts.push(el('path', { d: 'M142 166 L128 186 L144 214 L156 172 Z', fill: '#E6EBF1' }));
      if (c.accessory === 'stethoscope') {
        parts.push(el('path', {
          d: 'M100 172 Q98 206 116 212', fill: 'none', stroke: '#54606E', 'stroke-width': '5', 'stroke-linecap': 'round',
        }));
        parts.push(el('circle', { cx: 122, cy: 214, r: 9, fill: '#8C98A6' }));
        parts.push(el('circle', { cx: 122, cy: 214, r: 4.5, fill: '#DDE3EA' }));
      }
      break;
    }
    case 'chefJacket': {
      parts.push(torso('#FAFAF7'));
      parts.push(el('path', { d: 'M104 166 L120 186 L136 166 Q120 160 104 166 Z', fill: SKIN[c.skinTone].base }));
      parts.push(el('path', { d: 'M112 182 L120 176 L128 182 L120 192 Z', fill: c.accent }));
      for (const [x, y] of [[102, 200], [102, 216], [138, 200], [138, 216]]) {
        parts.push(el('circle', { cx: x, cy: y, r: 3.5, fill: '#C9CED6' }));
      }
      break;
    }
    case 'vest': {
      const helmetColor = slug === 'engineer-female' ? '#F26B5E' : '#3E6FB0';
      parts.push(torso(helmetColor));
      parts.push(el('path', { d: 'M58 242 C58 200 84 176 120 176 C156 176 182 200 182 242 Z', fill: '#F59E2D' }));
      parts.push(el('rect', { x: 60, y: 206, width: 120, height: 11, fill: '#DDE3EA' }));
      parts.push(el('rect', { x: 60, y: 206, width: 120, height: 11, fill: 'none', stroke: '#C4CBD4', 'stroke-width': 1 }));
      parts.push(el('path', { d: 'M112 176 L120 242 L128 176', fill: 'none', stroke: '#E08A17', 'stroke-width': 4 }));
      parts.push(shirtV('#2E5486'));
      break;
    }
    case 'pilotUniform': {
      parts.push(torso('#22355C'));
      parts.push(shirtV('#F7F9FB'));
      parts.push(el('path', { d: 'M116 178 L124 178 L122 206 L120 214 L118 206 Z', fill: '#D94F42' }));
      parts.push(el('rect', { x: 52, y: 178, width: 26, height: 9, rx: 4, fill: '#FFC928' }));
      parts.push(el('rect', { x: 162, y: 178, width: 26, height: 9, rx: 4, fill: '#FFC928' }));
      parts.push(el('circle', { cx: 100, cy: 216, r: 3, fill: '#FFC928' }));
      parts.push(el('circle', { cx: 140, cy: 216, r: 3, fill: '#FFC928' }));
      break;
    }
    case 'policeUniform': {
      parts.push(torso('#2A3B6E'));
      parts.push(el('path', { d: 'M104 166 L120 188 L136 166 Q120 160 104 166 Z', fill: '#1E2C54' }));
      parts.push(el('path', {
        d: 'M148 196 l4.7 9.5 10.5 1.5 -7.6 7.4 1.8 10.4 -9.4 -4.9 -9.4 4.9 1.8 -10.4 -7.6 -7.4 10.5 -1.5 Z',
        fill: '#FFC928',
      }));
      parts.push(el('rect', { x: 54, y: 180, width: 22, height: 8, rx: 4, fill: '#46628F' }));
      parts.push(el('rect', { x: 164, y: 180, width: 22, height: 8, rx: 4, fill: '#46628F' }));
      break;
    }
    case 'fireUniform': {
      parts.push(torso('#3E3A45'));
      parts.push(el('rect', { x: 44, y: 200, width: 152, height: 11, fill: '#FFC928' }));
      parts.push(el('rect', { x: 44, y: 224, width: 152, height: 8, fill: '#DDE3EA' }));
      parts.push(el('path', { d: 'M112 170 L128 170 L128 242 L112 242 Z', fill: '#2E2B35' }));
      for (const y of [186, 218]) {
        parts.push(el('rect', { x: 114, y, width: 12, height: 7, rx: 2, fill: '#8C98A6' }));
      }
      break;
    }
    case 'suit': {
      const jacket = c.gender === 'female' ? '#46628F' : '#2E3A4E';
      parts.push(torso(jacket));
      parts.push(shirtV('#F7F9FB'));
      if (c.gender === 'male') {
        parts.push(el('path', { d: 'M116 178 L124 178 L122 208 L120 216 L118 208 Z', fill: c.accent }));
      } else {
        parts.push(el('circle', { cx: 120, cy: 182, r: 4, fill: '#FFC928' }));
      }
      parts.push(el('path', { d: 'M98 166 L112 188 L100 210 L88 172 Z', fill: shade(jacket, 0.2) }));
      parts.push(el('path', { d: 'M142 166 L128 188 L140 210 L152 172 Z', fill: shade(jacket, 0.2) }));
      break;
    }
    case 'blazer': {
      const color = BLAZER_COLORS[slug] || '#46628F';
      parts.push(torso(color));
      parts.push(shirtV('#F7F9FB'));
      parts.push(el('path', { d: 'M98 166 L112 188 L100 212 L88 172 Z', fill: shade(color, 0.18) }));
      parts.push(el('path', { d: 'M142 166 L128 188 L140 212 L152 172 Z', fill: shade(color, 0.18) }));
      break;
    }
    case 'casual': {
      const color = CASUAL_COLORS[slug] || '#4C6A92';
      parts.push(torso(color));
      parts.push(el('path', { d: 'M100 166 Q120 184 140 166 Q120 160 100 166 Z', fill: shade(color, 0.25) }));
      break;
    }
    case 'overalls': {
      const shirt = OVERALL_SHIRT[slug] || '#3E8E7E';
      parts.push(torso(shirt));
      parts.push(el('rect', { x: 90, y: 196, width: 60, height: 46, rx: 8, fill: '#4C6A92' }));
      parts.push(el('path', { d: 'M74 176 L96 202 L104 194 L86 170 Z', fill: '#4C6A92' }));
      parts.push(el('path', { d: 'M166 176 L144 202 L136 194 L154 170 Z', fill: '#4C6A92' }));
      parts.push(el('circle', { cx: 100, cy: 202, r: 3.5, fill: '#FFC928' }));
      parts.push(el('circle', { cx: 140, cy: 202, r: 3.5, fill: '#FFC928' }));
      parts.push(el('rect', { x: 108, y: 214, width: 24, height: 16, rx: 4, fill: '#3E5A80' }));
      break;
    }
    case 'apron': {
      parts.push(torso('#8A5A44'));
      parts.push(el('path', { d: 'M92 184 L148 184 L156 242 L84 242 Z', fill: '#C89B6B' }));
      parts.push(el('path', { d: 'M92 184 Q120 176 148 184', fill: 'none', stroke: '#A87C4F', 'stroke-width': 4 }));
      parts.push(el('rect', { x: 104, y: 206, width: 32, height: 18, rx: 5, fill: '#B3854F' }));
      break;
    }
    case 'stylish': {
      parts.push(torso('#D65B8A'));
      parts.push(el('path', { d: 'M96 166 L144 166 L138 186 L102 186 Z', fill: '#B94571' }));
      for (const x of [108, 120, 132]) {
        parts.push(el('circle', { cx: x, cy: 178, r: 3, fill: '#FFC928' }));
      }
      break;
    }
    default:
      parts.push(torso('#4C6A92'));
  }
  return parts.join('');
}

/* -------------------------------- hair -------------------------------- */

function hairBack(c) {
  const hc = HAIR[c.hairColor] || HAIR.black;
  switch (c.hairStyle) {
    case 'long':
      return el('path', {
        d: 'M62 98 Q62 34 120 34 Q178 34 178 98 L178 172 Q178 188 162 188 L78 188 Q62 188 62 172 Z',
        fill: hc,
      });
    case 'curlyLong':
      return [
        el('circle', { cx: 120, cy: 82, r: 58, fill: hc }),
        el('circle', { cx: 68, cy: 118, r: 24, fill: hc }),
        el('circle', { cx: 172, cy: 118, r: 24, fill: hc }),
        el('circle', { cx: 62, cy: 148, r: 20, fill: hc }),
        el('circle', { cx: 178, cy: 148, r: 20, fill: hc }),
      ].join('');
    case 'hijab': {
      const color = HIJAB_COLORS[c.slug] || '#35577D';
      return el('path', {
        d: 'M120 26 Q56 28 52 102 Q50 156 86 174 L154 174 Q190 156 188 102 Q184 28 120 26 Z',
        fill: color,
      });
    }
    case 'bun': {
      const r = c.gender === 'male' ? 12 : 16;
      return el('circle', { cx: 120, cy: 36, r, fill: hc });
    }
    default:
      return '';
  }
}

function hairFront(c) {
  const hc = HAIR[c.hairColor] || HAIR.black;
  const dome = (inner) =>
    el('path', { d: `M75 98 Q74 40 120 40 Q166 40 165 98 ${inner} Z`, fill: hc });
  switch (c.hairStyle) {
    case 'short':
      return dome('L165 86 Q165 64 120 64 Q75 64 75 86');
    case 'receding':
      return dome('L165 92 Q162 56 142 54 Q128 53 120 66 Q112 53 98 54 Q78 56 75 92');
    case 'long':
      return dome('L165 84 Q165 62 120 62 Q75 62 75 84');
    case 'bun':
      return dome('L165 84 Q165 62 120 62 Q75 62 75 84');
    case 'curly':
      return [
        el('path', { d: 'M76 98 Q76 54 120 54 Q164 54 164 98 L164 86 Q164 68 120 68 Q76 68 76 86 Z', fill: hc }),
        el('circle', { cx: 86, cy: 72, r: 15, fill: hc }),
        el('circle', { cx: 103, cy: 58, r: 16, fill: hc }),
        el('circle', { cx: 120, cy: 52, r: 16, fill: hc }),
        el('circle', { cx: 137, cy: 58, r: 16, fill: hc }),
        el('circle', { cx: 154, cy: 72, r: 15, fill: hc }),
      ].join('');
    case 'curlyLong':
      return dome('L165 84 Q165 62 120 62 Q75 62 75 84');
    case 'bald':
      return el('path', {
        d: 'M92 52 Q104 44 120 44', fill: 'none', stroke: '#FFFFFF', 'stroke-width': 5,
        'stroke-linecap': 'round', opacity: 0.35,
      });
    case 'hijab': {
      const color = HIJAB_COLORS[c.slug] || '#35577D';
      return [
        el('path', { d: 'M75 100 Q74 44 120 44 Q166 44 165 100 L165 84 Q165 60 120 60 Q75 60 75 84 Z', fill: color }),
        el('path', {
          d: 'M74 106 Q78 158 120 160 Q162 158 166 106 L166 132 Q160 172 120 174 Q80 172 74 132 Z',
          fill: color,
        }),
      ].join('');
    }
    default:
      return '';
  }
}

/* -------------------------------- face -------------------------------- */

function face(c) {
  const parts = [];
  const skin = SKIN[c.skinTone];

  parts.push(el('circle', { cx: 96, cy: 118, r: 7, fill: '#F26B5E', opacity: 0.28 }));
  parts.push(el('circle', { cx: 144, cy: 118, r: 7, fill: '#F26B5E', opacity: 0.28 }));

  for (const cx of [102, 138]) {
    parts.push(el('circle', { cx, cy: 100, r: 5.6, fill: '#332A26' }));
    parts.push(el('circle', { cx: cx + 2, cy: 98, r: 1.9, fill: '#FFFFFF' }));
  }

  const browColor = c.hairColor === 'covered' ? '#3A2E28' : HAIR[c.hairColor];
  parts.push(el('path', { d: 'M92 86 Q102 80 112 86', fill: 'none', stroke: browColor, 'stroke-width': 4.4, 'stroke-linecap': 'round' }));
  parts.push(el('path', { d: 'M128 86 Q138 80 148 86', fill: 'none', stroke: browColor, 'stroke-width': 4.4, 'stroke-linecap': 'round' }));

  parts.push(el('path', { d: 'M115 110 Q120 116 125 110', fill: 'none', stroke: skin.shade, 'stroke-width': 4, 'stroke-linecap': 'round' }));

  if (c.beardStyle !== 'none') {
    const hc = HAIR[c.hairColor] || HAIR.black;
    const beardPath = c.beardStyle === 'full'
      ? 'M76 98 Q78 156 120 158 Q162 156 164 98 L164 94 Q150 116 120 116 Q90 116 76 94 Z'
      : 'M80 104 Q84 148 120 150 Q156 148 160 104 L160 100 Q148 118 120 118 Q92 118 80 100 Z';
    parts.push(el('path', { d: beardPath, fill: hc }));
    parts.push(el('circle', { cx: 120, cy: 130, r: 12, fill: skin.base }));
    parts.push(el('path', { d: 'M110 126 Q120 134 130 126', fill: 'none', stroke: '#5E4034', 'stroke-width': 4, 'stroke-linecap': 'round' }));
    parts.push(el('path', {
      d: 'M102 121 Q111 114 120 121 Q129 114 138 121 Q129 127 120 124 Q111 127 102 121 Z', fill: hc,
    }));
  } else {
    parts.push(el('path', { d: 'M107 124 Q120 136 133 124', fill: 'none', stroke: '#B4574B', 'stroke-width': 4.6, 'stroke-linecap': 'round' }));
  }

  if (c.hasGlasses) {
    const glassFill = 'rgba(255,255,255,0.14)';
    parts.push(el('rect', { x: 87, y: 88, width: 28, height: 23, rx: 8, fill: glassFill, stroke: OUTLINE, 'stroke-width': 4.6 }));
    parts.push(el('rect', { x: 125, y: 88, width: 28, height: 23, rx: 8, fill: glassFill, stroke: OUTLINE, 'stroke-width': 4.6 }));
    parts.push(el('path', { d: 'M115 97 L125 97', stroke: OUTLINE, 'stroke-width': 4.6, 'stroke-linecap': 'round', fill: 'none' }));
    parts.push(el('path', { d: 'M87 96 L76 93 M153 96 L164 93', stroke: OUTLINE, 'stroke-width': 4, 'stroke-linecap': 'round', fill: 'none' }));
  }

  return parts.join('');
}

/* ------------------------------ headwear ------------------------------ */

function headwear(c) {
  switch (c.headwear) {
    case 'helmet': {
      const color = c.slug === 'engineer-female' ? '#F2F5F8'
        : c.slug === 'electrician-male' ? '#F59E2D' : '#FFC928';
      return [
        el('path', { d: 'M70 76 Q70 30 120 30 Q170 30 170 76 Z', fill: color }),
        el('rect', { x: 60, y: 72, width: 120, height: 13, rx: 6.5, fill: shade(color, 0.12) }),
        el('rect', { x: 110, y: 30, width: 20, height: 22, rx: 9, fill: shade(color, 0.12) }),
      ].join('');
    }
    case 'fireHelmet':
      return [
        el('path', { d: 'M66 76 Q66 28 120 28 Q174 28 174 76 Z', fill: '#D94F42' }),
        el('ellipse', { cx: 120, cy: 78, rx: 62, ry: 11, fill: '#B93E33' }),
        el('path', { d: 'M112 44 L128 44 L126 62 L114 62 Z', fill: '#FFC928' }),
      ].join('');
    case 'chefHat':
      return [
        el('circle', { cx: 96, cy: 42, r: 18, fill: '#FAFAF7' }),
        el('circle', { cx: 120, cy: 32, r: 20, fill: '#FAFAF7' }),
        el('circle', { cx: 144, cy: 42, r: 18, fill: '#FAFAF7' }),
        el('path', { d: 'M88 44 L152 44 L150 74 L90 74 Z', fill: '#FAFAF7' }),
        el('rect', { x: 88, y: 68, width: 64, height: 9, rx: 4.5, fill: '#E1E4E8' }),
      ].join('');
    case 'pilotCap':
      return [
        el('path', { d: 'M72 72 Q72 34 120 34 Q168 34 168 72 Z', fill: '#22355C' }),
        el('path', { d: 'M72 72 L168 72 L168 64 Q120 78 72 64 Z', fill: '#FFC928' }),
        el('path', { d: 'M78 76 Q120 94 162 76 L162 68 Q120 84 78 68 Z', fill: '#1B2233' }),
        el('circle', { cx: 120, cy: 54, r: 6.5, fill: '#FFC928' }),
      ].join('');
    case 'policeCap':
      return [
        el('path', { d: 'M72 72 Q72 34 120 34 Q168 34 168 72 Z', fill: '#2A3B6E' }),
        el('path', { d: 'M78 76 Q120 94 162 76 L162 68 Q120 84 78 68 Z', fill: '#1B2233' }),
        el('path', {
          d: 'M120 44 l3.2 6.5 7.2 1 -5.2 5 1.2 7.1 -6.4 -3.4 -6.4 3.4 1.2 -7.1 -5.2 -5 7.2 -1 Z',
          fill: '#FFC928',
        }),
      ].join('');
    case 'sunHat':
      return [
        el('ellipse', { cx: 120, cy: 70, rx: 68, ry: 15, fill: '#E3B94E' }),
        el('path', { d: 'M84 70 Q84 26 120 26 Q156 26 156 70 Z', fill: '#E3B94E' }),
        el('path', { d: 'M84 62 L156 62 L156 70 L84 70 Z', fill: '#D94F42' }),
      ].join('');
    default:
      return '';
  }
}

/* ---------------------------- accessory badge ---------------------------- */

function badgeIcon(kind) {
  const s = (d, extra = {}) => el('path', { d, fill: 'none', stroke: '#173B6C', 'stroke-width': 3.4, 'stroke-linecap': 'round', 'stroke-linejoin': 'round', ...extra });
  const f = (d, fill = '#173B6C') => el('path', { d, fill });
  switch (kind) {
    case 'stethoscope':
      return s('M-8 -10 Q-8 2 0 4 Q8 2 8 -10') + el('circle', { cx: 0, cy: 10, r: 5, fill: 'none', stroke: '#173B6C', 'stroke-width': 3.4 }) + s('M0 4 L0 5');
    case 'camera':
      return f('M-11 -5 L-4 -5 L-2 -9 L4 -9 L6 -5 L11 -5 Q13 -5 13 -3 L13 8 Q13 10 11 10 L-11 10 Q-13 10 -13 8 L-13 -3 Q-13 -5 -11 -5 Z') +
        el('circle', { cx: 0, cy: 2, r: 5, fill: '#FFC928' });
    case 'laptop':
      return f('M-10 -8 L10 -8 L10 4 L-10 4 Z') + f('M-13 6 L13 6 L11 10 L-11 10 Z', '#4FB3E8') + el('rect', { x: -7, y: -5, width: 14, height: 6, fill: '#4FB3E8' });
    case 'book':
      return s('M0 -8 Q-6 -12 -12 -9 L-12 8 Q-6 5 0 9 Q6 5 12 8 L12 -9 Q6 -12 0 -8 Z') + s('M0 -8 L0 9');
    case 'wheat':
      return s('M0 12 L0 -10') +
        f('M0 -12 Q-5 -7 0 -2 Q5 -7 0 -12 Z', '#F5A800') +
        f('M-2 -4 Q-8 -1 -8 5 Q-2 3 -2 -4 Z', '#F5A800') +
        f('M2 -4 Q8 -1 8 5 Q2 3 2 -4 Z', '#F5A800');
    case 'scales':
      return s('M0 -10 L0 8 M-10 -7 L10 -7 M-14 10 L14 10') +
        s('M-10 -7 L-13 2 M-10 -7 L-7 2 M-13 2 Q-10 6 -7 2') +
        s('M10 -7 L7 2 M10 -7 L13 2 M7 2 Q10 6 13 2');
    case 'mic':
      return f('M-4 -12 L4 -12 Q7 -12 7 -8 L7 2 Q7 6 3 6 L-3 6 Q-7 6 -7 2 L-7 -8 Q-7 -12 -4 -12 Z') + s('M0 6 L0 12') + el('rect', { x: -3, y: -9, width: 10, height: 6, fill: '#F26B5E' });
    case 'bread':
      return f('M-12 6 Q-12 -8 0 -8 Q12 -8 12 6 Q12 9 9 9 L-9 9 Q-12 9 -12 6 Z', '#E3B94E') +
        s('M-5 -2 L-3 2 M1 -3 L3 1 M6 0 L8 4', { stroke: '#B3854F', 'stroke-width': 2.6 });
    case 'briefcase':
      return f('M-12 -4 L12 -4 Q14 -4 14 -2 L14 8 Q14 10 12 10 L-12 10 Q-14 10 -14 8 L-14 -2 Q-14 -4 -12 -4 Z') +
        s('M-5 -4 L-5 -9 L5 -9 L5 -4') + el('rect', { x: -3, y: 0, width: 6, height: 4, rx: 1, fill: '#FFC928' });
    case 'wrench':
      return f('M-10 -6 Q-13 -12 -7 -13 L-3 -9 L-1 -11 L-5 -14 Q2 -16 3 -9 Q3 -6 0 -4 L9 8 Q11 11 8 13 Q5 14 3 11 L-5 -1 Q-9 -1 -10 -6 Z');
    case 'bulb':
      return f('M0 -12 Q9 -12 9 -3 Q9 2 4 5 L-4 5 Q-9 2 -9 -3 Q-9 -12 0 -12 Z', '#FFC928') +
        el('rect', { x: -4, y: 6, width: 8, height: 5, rx: 2, fill: '#173B6C' }) +
        s('M-13 -10 L-10 -8 M13 -10 L10 -8 M0 -16 L0 -14', { 'stroke-width': 2.6 });
    case 'tape':
      return el('circle', { cx: -2, cy: 0, r: 9, fill: 'none', stroke: '#173B6C', 'stroke-width': 3.4 }) +
        el('circle', { cx: -2, cy: 0, r: 3, fill: '#173B6C' }) +
        f('M6 -2 L14 -2 L14 4 L6 4 Z', '#FFC928');
    case 'dentalMirror':
      return el('circle', { cx: -4, cy: -6, r: 6, fill: 'none', stroke: '#173B6C', 'stroke-width': 3.4 }) +
        el('circle', { cx: -4, cy: -6, r: 2.5, fill: '#4FB3E8' }) + s('M0 -1 L10 11');
    case 'medicine':
      return f('M-6 -6 L6 -6 L6 10 Q6 12 4 12 L-4 12 Q-6 12 -6 10 Z', '#2FBF9B') +
        el('rect', { x: -7, y: -12, width: 14, height: 6, rx: 2, fill: '#173B6C' }) +
        f('M-2 0 L2 0 L2 2 L4 2 L4 6 L2 6 L2 8 L-2 8 L-2 6 L-4 6 L-4 2 L-2 2 Z', '#FFFFFF');
    case 'tablet':
      return f('M-10 -10 L8 -10 Q10 -10 10 -8 L10 8 Q10 10 8 10 L-10 10 Q-12 10 -12 8 L-12 -8 Q-12 -10 -10 -10 Z') +
        el('rect', { x: -8, y: -6, width: 14, height: 12, fill: '#4FB3E8' }) + s('M8 -12 L14 -6', { stroke: '#F5A800' });
    case 'blueprint':
      return f('M-12 -8 L12 -8 L12 8 L-12 8 Z', '#4FB3E8') +
        s('M-7 -3 L2 -3 M-7 2 L5 2 M-7 -3 L-7 4', { stroke: '#FFFFFF', 'stroke-width': 2.6 }) +
        el('circle', { cx: 7, cy: -1, r: 3, fill: 'none', stroke: '#FFFFFF', 'stroke-width': 2.2 });
    case 'spoon':
      return el('ellipse', { cx: 0, cy: -7, rx: 5.5, ry: 7, fill: '#173B6C' }) + s('M0 0 L0 13');
    default:
      return '';
  }
}

function accessoryBadge(c) {
  if (c.accessory === 'none') return '';
  return el('g', { transform: 'translate(196,196)' },
    el('circle', { cx: 0, cy: 0, r: 26, fill: '#FFFFFF', stroke: tint(c.accent, 0.4), 'stroke-width': 4 }) +
    badgeIcon(c.accessory)
  );
}

/* -------------------------------- render -------------------------------- */

export function renderAvatar(c, { size = 240 } = {}) {
  const skin = SKIN[c.skinTone];
  const bg = tint(c.accent, 0.8);
  const halo = tint(c.accent, 0.62);

  const svg = [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" width="${size}" height="${size}" role="img">`,
    el('rect', { x: 0, y: 0, width: 240, height: 240, rx: 28, fill: bg }),
    el('circle', { cx: 120, cy: 118, r: 86, fill: halo }),
    hairBack(c),
    clothing(c),
    // neck
    el('path', { d: 'M104 132 L136 132 L136 168 Q120 176 104 168 Z', fill: skin.shade }),
    // head + ears
    el('circle', { cx: 74, cy: 104, r: 10, fill: skin.base }),
    el('circle', { cx: 166, cy: 104, r: 10, fill: skin.base }),
    el('ellipse', { cx: 120, cy: 100, rx: 46, ry: 50, fill: skin.base }),
    face(c),
    hairFront(c),
    headwear(c),
    accessoryBadge(c),
    '</svg>',
  ];
  return svg.join('');
}

// Mystery card used for the hidden secret character.
export function renderMysteryCard() {
  return [
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" width="240" height="240" role="img">',
    el('rect', { x: 0, y: 0, width: 240, height: 240, rx: 28, fill: '#1E63C8' }),
    el('circle', { cx: 120, cy: 120, r: 86, fill: '#3B82E0' }),
    el('text', {
      x: 120, y: 158, 'text-anchor': 'middle', 'font-size': 120, 'font-family': 'Arial, sans-serif',
      'font-weight': 'bold', fill: '#FFC928',
    }, '؟'),
    '</svg>',
  ].join('');
}
