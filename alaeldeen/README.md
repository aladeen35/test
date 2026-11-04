# Eng. Alaeldeen | Quality & Safety

A bilingual (Arabic RTL / English LTR) professional website with the **Quality Lamp | مصباح الجودة**
learning platform, the **Quality Toolkit** and the **Quality Dictionary** built into it.

It's a static site with no build step: open `index.html` or serve the folder (GitHub Pages works as is).

## What's in it

| Area | Route | State |
|---|---|---|
| Home: hero, specialties strip, quick access, verified facts | `#/` | Done |
| Profile: summary, experience timeline, education, 16 certificates, skills, achievements, AR/EN CV download | `#/about`, `#/experience`, `#/certifications` | Done, all data from the current CV |
| Quality Lamp: 12 modules, learner dashboard, role paths, badges, quiz history | `#/lamp` | 5 full lessons (GMP, GHP, HACCP, Temperature, Allergens); 7 marked *coming soon* |
| Lesson template: definition, why, requirements, steps, factory/kitchen/café examples, mistakes, printable checklist, case study, quiz with explanations, references, review date | `#/lamp/<id>` | Done |
| Toolkit: GMP/GHP inspection checklist (with compliance % and one-click NCRs), NCR with before/after photos and status flow, RCA (5 Whys + fishbone) & CAPA, 5×5 risk register, temperature log with deviation flags and chart, dilution calculator, compliance calculator | `#/tools/<id>` | Done. Print/PDF, CSV/JSON export, JSON import |
| Dictionary: 25 terms, AR/EN search with Arabic normalisation, category filters, favourites, pronunciation, suggest a term | `#/dictionary` | Done |
| Knowledge Center: 3 articles/guides with author, dates and references, FAQ, official sources | `#/knowledge` | Done |
| Projects: problem / role / method / result / lesson | `#/projects` | Done |
| Contact (mailto + WhatsApp, no server), privacy & terms | `#/contact`, `#/privacy` | Done |
| Global search (`/` key) across pages, lessons, tools, terms, articles | header | Done |
| PWA manifest + offline service worker | | Done (works on HTTPS) |
| Accounts, admin panel, database (spec phase 4) | | Not built. Data stays in the visitor's browser (localStorage) |

## Editing content

Everything visible lives in two files:

- `js/content.js`: profile, experience, certificates, lessons, quizzes, dictionary terms, articles, projects.
  Each text is `{ ar: "...", en: "..." }`.
- `js/i18n.js`: interface labels.

Add a lesson by setting a module's `status` to `"ready"` and giving it a `lesson` and `quiz` (copy the GMP module as a template).
After changing files, bump `VERSION` in `sw.js` so installed copies refresh.

## Before going live (from spec section 16)

- LinkedIn / YouTube links weren't provided, so they're left out. Add them in the footer in `js/app.js`.
- Audit scores (98% / 100%) aren't in the current CV, so they aren't shown. Add them only with their audit context.
- Lesson content is marked as a teaching draft pending technical review. Update `REVIEWED` in `content.js` after review.
- Confirm you're happy publishing the phone number and email (shown on the profile and contact pages and in the CV PDFs).
