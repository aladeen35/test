# أنا مِنو 🤔 — Ana Meno

**An original Arabic two-player online guessing game (PWA).** Each player receives a
random secret character out of 30 professionally-dressed cartoon characters. Players
alternate yes/no questions, eliminate candidates on their own board, and race to
guess the opponent's character. Faster wins with fewer questions score more points.

- **Language / direction:** Arabic-only UI, full RTL.
- **Stack:** React 18 + TypeScript + Vite + Tailwind CSS + Supabase (PostgreSQL + Realtime).
- **Multiplayer:** room-code based, server-authoritative (PostgreSQL RPCs + RLS).
- **PWA:** installable, offline app shell, self-hosted Cairo font, custom service worker.

---

## Prerequisites

- Node.js ≥ 18 (developed on Node 22)
- npm ≥ 9
- A free [Supabase](https://supabase.com) project (for real online multiplayer)

## Installation

```bash
cd ana-meno
npm install
```

## npm commands

| Command | Purpose |
|---|---|
| `npm run dev` | Start the Vite dev server |
| `npm run build` | Type-check + production build into `dist/` |
| `npm run preview` | Serve the production build locally |
| `npm test` | Run the unit/integration test suite (Vitest, 61 tests) |
| `npm run generate:characters` | Regenerate the 30 SVG character portraits from `src/data/characters.json` |
| `npm run generate:icons` | Regenerate PWA PNG icons from `public/icons/icon.svg` (needs Chromium) |
| `node scripts/generate-seed.mjs` | Regenerate `supabase/seed.sql` from the JSON data |
| `node scripts/e2e-local.mjs` | Headless two-player acceptance test against `npm run preview` |

## Environment variables

Copy `.env.example` to `.env` and fill in:

```
VITE_SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR-ANON-PUBLIC-KEY
```

- The **anon (public) key** is safe to ship to browsers — Row Level Security protects the data.
- **Never** put the service-role key in this file or anywhere in the frontend.
- Without these variables the app automatically runs the **local development
  backend** (two tabs of the same browser play against each other). Production
  deployments must configure Supabase — the local mode is not real multiplayer.

## Supabase project setup

1. Create a project at [database.new](https://database.new).
2. **Enable anonymous sign-in:** Dashboard → *Authentication → Sign In / Up →
   Anonymous Sign-Ins → Enable*. The game uses anonymous auth (no accounts in V1);
   each browser gets a stable `auth.uid()` used by all RLS policies.
3. **Apply the schema (migration):** open *SQL Editor* and run the contents of
   [`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql).
   This creates the tables (`characters`, `questions`, `rooms`, `games`,
   `game_secrets`, `game_questions`), all RLS policies, the authoritative game
   RPC functions, and adds `rooms`/`games`/`game_questions` to the
   `supabase_realtime` publication.
   - Using the CLI instead: `supabase db push` with this repo's `supabase/` directory.
4. **Seed the data:** run [`supabase/seed.sql`](supabase/seed.sql) in the SQL editor
   (30 characters + 28 predefined questions). The file is generated — regenerate it
   with `node scripts/generate-seed.mjs` after editing the JSON data.
5. Copy the project URL + anon key into `.env`.

### Realtime configuration

The migration already runs
`alter publication supabase_realtime add table rooms, games, game_questions;`.
No dashboard toggles are needed. Clients subscribe to `postgres_changes` filtered
by room, and RLS guarantees only room members receive the rows. Presence on the
same channel powers the opponent online/offline indicator.

### Security model (V1)

- Secret characters live in **`game_secrets`**, readable only where
  `player_id = auth.uid()` — the opponent's secret never reaches the client,
  neither in app state nor in any network payload.
- `games.revealed_secrets` is populated **by the server** only when a game finishes.
- There are **no insert/update/delete policies** on any table: every mutation goes
  through `SECURITY DEFINER` RPCs (`create_room`, `join_room`, `ask_question`,
  `answer_question`, `submit_guess`, `timeout_turn`, `request_rematch`,
  `leave_room`) which validate membership, turn order, pending questions,
  character/question validity, and the turn timer on the server.
- Secret assignment randomness uses `order by gen_random_uuid()` (pgcrypto).
- Room codes use a confusion-free alphabet (no O/0, I/1, S/5) and are case-insensitive.

## Local development

```bash
npm run dev
```

Without Supabase credentials the app uses the **local backend**: open the printed
URL in **two tabs** of the same browser — one creates a room, the other joins with
the code. The local backend runs the exact same rule engine
(`src/game/serverLogic.ts`) that the SQL functions mirror, so game logic can be
developed and tested without a network. With `.env` filled in, the dev server
talks to real Supabase.

## Testing

```bash
npm test
```

Covers: room creation/joining, invalid codes, the two-player limit, room expiry,
secret-character uniqueness and privacy, turn validation, question validation,
answer validation (defender-only), guess validation, scoring, timeout+refund,
forfeit/disconnect, reconnect (resume), rematch, and question fairness across all
30 characters (every question is deterministically answerable and splits the cast).

End-to-end (drives the real UI in headless Chromium through the full two-player
match, including rematch):

```bash
npm run build
npx vite preview --port 4173 &
CHROME_BIN="$(which chromium || echo /path/to/chrome)" node scripts/e2e-local.mjs
```

## Production build & deployment

```bash
npm run build   # outputs dist/
```

Deploy `dist/` to any static host (Netlify, Vercel, Cloudflare Pages, GitHub Pages…):

1. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` as build-time environment
   variables in your host's settings (they are inlined at build time).
2. Configure SPA fallback (serve `index.html` for unknown paths) — the app is a
   single page. Netlify: `/*  /index.html  200`; Vercel: rewrite all to `/`.
3. Serve over **HTTPS** (required for service workers / installability).

### PWA

- `public/manifest.webmanifest` — name **"أنا مِنو 🤔"**, short name **"أنا مِنو"**,
  RTL, standalone, portrait, theme `#1E63C8`, SVG + PNG + maskable icons.
- `public/sw.js` — precaches the shell (HTML, fonts, icons), caches character art
  on first use, network-first navigations with offline fallback. Supabase traffic
  is never intercepted; multiplayer requires connectivity by design.
- Icons regenerate from the single SVG source via `npm run generate:icons`.

## Character art pipeline

The 30 portraits are **generated SVGs** (`public/assets/characters/*.svg`) built
from the metadata in `src/data/characters.json` by `scripts/avatar.mjs` — one art
direction for the whole cast (1:1 crop, same lighting/proportions, profession-
identifying outfits and accessories). To swap in professionally illustrated
artwork later, replace the files at the **same paths** (e.g.
`public/assets/characters/engineer-male.svg` → same name, or update `imageUrl`
in the seed) — no game-logic changes required.

## Project layout

```
ana-meno/
├── public/            # PWA manifest, service worker, icons, fonts, character art
├── scripts/           # generators (characters, icons, SQL seed) + e2e test
├── supabase/
│   ├── migrations/0001_init.sql   # schema + RLS + authoritative RPCs
│   └── seed.sql                   # generated: 30 characters + 28 questions
└── src/
    ├── data/          # characters.json, questions.json (single source of truth)
    ├── game/          # pure rules: types, logic, questions, serverLogic (+tests)
    ├── backend/       # GameBackend interface, SupabaseBackend, LocalBackend
    ├── state/         # React store (UI/game/network state separation)
    ├── audio/         # procedural WebAudio manager (no copyrighted assets)
    ├── components/    # cards, grid, modals, header, log, confetti, status bars
    └── screens/       # home, create, join, lobby, game, result, settings, tutorial
```

## Known limitations (V1)

- One game mode ("اللعب العادي"); AI opponent, 4-player, rankings etc. are reserved
  for V2 — the backend interface and rule engine are already separated to support them.
- The local development backend shares state between tabs of one browser only and
  is intentionally not a production path.
- Turn-timer enforcement is validated server-side when reported, but an idle game
  with both clients closed simply expires with its room.
