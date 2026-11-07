# Design system

Direction: **modern humanitarian healthcare** — clean white surfaces, strong medical red for action, dark navy for text and trust, rounded cards, clear status labels, large touch targets. Arabic first.

## Brand

**Name:** FAZAT DAM · فزعة دم
**Slogans:** فزعتك حياة.. وقطرتك أمل — *Your Support Saves Lives.*

**Logo concept** (from the approved logo sheet): a red blood drop carrying a white heartbeat line, cradled by two hands — the left hand navy, the right hand red — meeting beneath the drop. It reads as *care, urgency and community holding each other up*. Wordmark: «فزعة دم» in bold navy Arabic, `FAZAT DAM` in bold navy capitals.

The platform uses the client's own approved logo, unchanged. Assets are PNG crops of the logo sheet `docs/brand/logo-concept-sheet.png`, stored in `public/brand/`, plus PWA sizes in `public/icons/`.

> **Before any print use** (banners, flyers, roll-ups, merchandise), request vector masters (SVG/AI/PDF) from the designer. The PNG crops are for screen use only. When vectors arrive, add them next to the PNGs with the same base names (`logo-full.svg`, …).

| Variant | File | Use |
|---|---|---|
| Full bilingual (symbol + Arabic + English + slogans) | `public/brand/logo-full.png` | About page, documents, splash |
| Arabic only | `public/brand/logo-ar.png` | Arabic header |
| English only | `public/brand/logo-en.png` | English header |
| Horizontal | `public/brand/logo-horizontal.png` | Wide headers, letterheads |
| Vertical | `public/brand/logo-vertical.png` | Narrow spaces, posters |
| Symbol only | `public/brand/symbol.png` | Small spaces, loaders |
| Mobile app icon (white tile / red tile) | `public/brand/app-icon.png`, `public/brand/app-icon-red.png` | Store-style icon, manifest source |
| Monochrome | `public/brand/logo-mono.png` | Print, single-colour use |
| Dark background (white) | `public/brand/logo-dark.png` | Navy/dark surfaces |
| Favicon | `src/app/icon.png`, `public/icons/favicon-64.png` | Browser tab |
| PWA icons | `public/icons/icon-192.png`, `icon-512.png`, `maskable-512.png`, `apple-icon.png`, `badge-96.png` (push badge) | Manifest, iOS home screen, notifications |
| Social profile (round / square) | `public/brand/social-circle.png`, `public/brand/social-square.png` | Social media avatars |

Rules: keep clear space equal to the height of the heartbeat line around the symbol; never recolour the hands, stretch, add shadows, or place the colour logo on red.

## Colour tokens

| Token | Hex | Role |
|---|---|---|
| `--color-primary` | `#C62828` | Primary actions, "I need blood", critical |
| `--color-primary-2` | `#E53935` | Hover, accents, illustrations (not for small text on white) |
| `--color-navy` | `#172B4D` | Text, headers, secondary buttons |
| `--color-white` | `#FFFFFF` | Surfaces |
| `--color-bg` | `#F4F6F8` | App background |
| `--color-success` | `#2E7D32` | Available, confirmed, completed |
| `--color-warning` | `#F9A825` | Pending, urgent |

Derived neutrals: `--color-muted #5B6B82` (secondary text, 5.6:1 on white), `--color-line #E3E8EF` (borders).

### Contrast (WCAG 2.1, computed)

| Foreground on background | Ratio | Result |
|---|---|---|
| Navy `#172B4D` on white | 14.1 : 1 | AAA |
| Navy on `#F4F6F8` | 13.0 : 1 | AAA |
| Red `#C62828` on white | 5.62 : 1 | AA text |
| White on red `#C62828` | 5.62 : 1 | AA text (buttons) |
| Red on `#F4F6F8` | 5.19 : 1 | AA text |
| Secondary red `#E53935` on white | 4.23 : 1 | Large text / icons only |
| Success `#2E7D32` on white | 5.13 : 1 | AA text |
| White on success | 5.13 : 1 | AA text |
| Warning `#F9A825` on white | 1.97 : 1 | **Fails** — never use as text on white |
| Navy on warning `#F9A825` | 7.16 : 1 | AAA — warning badges use navy text |

## Typography

| Use | Arabic | English | Size / line-height | Weight |
|---|---|---|---|---|
| Display | IBM Plex Sans Arabic | Inter | 28/36 | 700 |
| H1 | | | 22/30 | 700 |
| H2 | | | 18/26 | 600 |
| Body | | | 16/26 (Arabic) · 16/24 (English) | 400 |
| Small / meta | | | 14/22 | 500 |
| Button | | | 16/24 | 600 |

Fonts are self-hosted with `@fontsource/ibm-plex-sans-arabic` and `@fontsource-variable/inter` (no third-party font requests, works offline). Font stack: `"IBM Plex Sans Arabic", "Inter Variable", system-ui, sans-serif`; Latin glyphs inside Arabic text fall through to Inter. Numerals: Western digits (0-9) in both languages for phone numbers, references and blood units.

## Spacing, radius, elevation

- Spacing scale (px): 4, 8, 12, 16, 20, 24, 32, 40, 48. Page gutter 16 px on mobile, 24 px from 768 px.
- Radius: cards **16 px**, buttons and inputs 12 px, chips/badges 999 px, bottom sheet 24 px top corners.
- Elevation: `shadow-sm` (0 1px 2px rgb(23 43 77 / .06)) for cards; `shadow-md` (0 8px 24px rgb(23 43 77 / .10)) for sheets and the floating request button. No heavy shadows.

## Components

**Buttons** — min height 48 px (44 px minimum touch target everywhere).
- Primary: red fill, white text. Secondary: navy outline, navy text. Ghost: navy text. Danger: red outline.
- Large action tiles on Home: "أحتاج دم / I Need Blood" (red) and "أريد التبرع / I Want to Donate" (navy), full width, icon + label + one-line hint.
- Loading state keeps width; disabled at 40% opacity with `aria-disabled`.

**Cards** — white, 16 px radius, 16 px padding, 1 px `--color-line` border. Request card: blood-group chip, units, city, hospital, urgency badge, needed-by time, reference in small mono digits. Demo rows carry a grey "تجريبي · DEMO" badge.

**Blood-group chip** — 44×44 rounded square, red background, white bold text (`O+`); the outline version (red border, red text) means "selectable" in pickers.

**Status badges** (pill, 14 px, icon + text — never colour alone):

| Status | Arabic | Badge colours |
|---|---|---|
| submitted | تم الإرسال | navy text on `#E8ECF3` |
| under_review | قيد المراجعة | navy text on warning `#F9A825` |
| verified | تم التحقق | white on success `#2E7D32` |
| matching_donors | جارٍ البحث عن متبرعين | white on navy `#172B4D` |
| donors_responding | متبرعون يستجيبون | white on red `#C62828` |
| donation_arranged | تم ترتيب التبرع | success text on `#E6F2E7` |
| completed | مكتمل | white on success `#2E7D32` |
| rejected | مرفوض | red text on `#FDECEC` |
| cancelled | ملغى | muted text on `#EEF1F5` |
| expired | منتهي | muted text on `#EEF1F5` |

Urgency: critical = red fill, urgent = navy on warning, normal = navy outline.

**Forms** — label above field, 48 px inputs, 12 px radius, helper text below, error text in red with an icon and `aria-describedby`. Phone fields are `dir="ltr"` with the country prefix select on the start side. Required consents are unticked checkboxes with full sentences.

**Bottom navigation** — 5 items, 64 px tall, safe-area padding; centre "request" item is a red circle; active item navy with label, inactive muted.

**Feedback** — toasts at top, offline banner (navy, persistent while offline), empty states with an illustration-free icon, a sentence and one action.

## RTL / LTR rules

- Use logical utilities only: `ms-*/me-*`, `ps-*/pe-*`, `start-*/end-*`, `text-start/text-end`, `border-s/border-e`, `rounded-s/e`. No `left/right` in components.
- Mirror directional icons (back/forward chevrons, arrows) with `rtl:-scale-x-100`. Do **not** mirror the logo, the heartbeat line, clocks, media controls or check marks.
- Phone numbers, references (`FD-SA-…`), blood groups and URLs are wrapped in `dir="ltr"` / `<bdi>`.
- Dates: Gregorian, localised month names; times in the network's zone (Asia/Riyadh, Africa/Khartoum).

## Accessibility

- WCAG 2.1 AA as the floor (see contrast table).
- Touch targets ≥ 44×44 px with 8 px spacing.
- Visible focus ring: 3 px `#172B4D` outline + 2 px white offset (red surfaces get a white ring).
- Every input has a `<label>`; status changes are announced through an `aria-live="polite"` region.
- Respect `prefers-reduced-motion`; no animation conveys meaning on its own.
- Language attribute on `<html>` follows the UI language so screen readers switch voice.

## Voice and tone

Warm, calm, direct. Urgency without panic. Never medical promises.

| Situation | Arabic | English |
|---|---|---|
| Primary call to action | أحتاج دم | I Need Blood |
| Donor call to action | أريد التبرع | I Want to Donate |
| Match request | هل تستطيع المساعدة؟ الأهلية النهائية يحددها بنك الدم. | Can you help? Final eligibility is decided by the blood bank. |
| Privacy reassurance | رقمك لا يظهر لأحد حتى توافق أنت. | Your number stays hidden until you agree. |
| Thanks after confirmation | تم تأكيد تبرعك — شكراً لفزعتك | Your donation was confirmed — thank you |
| Error (rate limit) | حاولت كثيراً خلال وقت قصير، انتظر قليلاً ثم أعد المحاولة. | Too many attempts in a short time. Please wait and try again. |

Avoid: "guaranteed", "compatible donor", "safe to donate", guilt language, exposing patient details.
