# NGƯU CÁT — Restaurant Booking UI (牛吉 予約管理)

Vue 3 + TypeScript frontend for a multi-role restaurant booking & POS system.

## Roles & Routes

| Role | Path prefix | Devices |
|------|-------------|---------|
| Admin | `/admin/*` | Desktop |
| Manager | `/manager/*` | Desktop |
| Reception (Cashier) | `/reception/*` | Desktop POS |
| Staff (Waiter) | `/staff/*` | Mobile |
| Customer (Guest) | `/tablet/*` | Tablet |

Default redirect: `/` → `/manager/dashboard`.

## Stack

- **Vue 3.5** (Composition API + `<script setup>`)
- **TypeScript** (`vue-tsc` strict, `noUnusedLocals`, `noUnusedParameters`)
- **Vite 8** — `@/` alias → `./src`
- **Pinia 3** — `useI18nStore` for locale switching
- **vue-i18n 9** — Vietnamese (`vi`) + Japanese (`ja`)
- **vue-router 4** — 5 portal trees
- **TailwindCSS 3** + `tailwindcss-animate` + custom "kawaii" CSS layer
- **lucide-vue-next** icons
- **date-fns 3**, **clsx** + **tailwind-merge** (`cn()`), **zod**

## Scripts

```bash
npm run dev      # vite dev server
npm run build    # vue-tsc -b && vite build
npm run preview  # serve the dist/ build
```

## Project Layout

```
src/
├── main.ts                # createApp + Pinia + router + i18n + i18nStore
├── App.vue                # <RouterView />
├── router/index.ts        # 5 portal route trees
├── layouts/               # Admin / Manager / Reception / Staff / Tablet layouts
│   └── DashboardLayout.vue
├── stores/i18n.ts         # Pinia locale store (sync with vue-i18n + <html lang>)
├── locales/               # vue-i18n setup (vi.ts, ja.ts, index.ts)
├── lib/
│   ├── utils.ts           # cn() — clsx + tailwind-merge
│   └── mock-data.ts       # Branches, Zones, Tables, Customers, Reservations, Menu
├── styles/
│   ├── globals.css        # Tailwind layers + "kawaii" CSS vars & utilities
│   └── styles.css
└── views/
    ├── TimelineView.vue   # /      → schedule grid by zone × time-slot
    ├── ListView.vue       # /list  → searchable table of reservations
    ├── FloorPlanView.vue  # /floor → table status by zone (day / realtime)
    └── {admin,manager,reception,staff,tablet}/
```

## State & Data

- All data lives in `src/lib/mock-data.ts` (2 branches, 4 zones, 16 tables, 10 customers, 15 reservations, 15 menu items).
- No backend is wired yet — see `docs/COST_ANALYSIS.md` for the planned Supabase Pro + Vercel deployment target.

## Internationalization

Locale switching is driven by `useI18nStore` (Pinia). On every change it:

1. Updates `i18n.global.locale` (vue-i18n)
2. Sets `<html lang>` and `<html data-locale>`
3. Persists to `localStorage` under `ngu-cat.locale`

Initial locale detection order: `localStorage` → `navigator.language` (Japanese → `ja`) → `vi`.

## Theme

"Kawaii Cute" palette — salmon pink `#FF7B89` + cream `#FFF5F7` + navy `#2C3E50`. All colors are exposed as CSS custom properties in `globals.css` and wired into Tailwind via `tailwind.config.ts`. Custom utility classes: `kawaii-card`, `kawaii-btn-primary`, `kawaii-btn-ghost`, `kawaii-pill`, `kawaii-input`, `kawaii-tab-active`, plus a custom scrollbar.

Fonts: Nunito (400-900) + Noto Sans JP, loaded via Google Fonts in `index.html`.

## Documentation

- `docs/COST_ANALYSIS.md` — Supabase Pro $25/mo + Vercel Free deployment cost analysis (VI/JA)
- `BUSINESS_ANALYSIS.md` — original product & UX analysis
- `RESTAURANT_SYSTEM_ANALYSIS.md` — original system & data-flow analysis

