# Anitracker — Codebase Overview & AWS Migration Plan

*Investigation date: 2026-10-02 · Repo: `https://github.com/Hephaestus2nd/Internet_Movie_Database.git` · Commit analyzed by prior graphify run: `dae0a7ba`*

---

## Summary

**Anitracker** is a small three-tier anime watchlist web application built for COSC349 Assignment 1. It is a **deliberately infrastructure-heavy, application-simple** project: the entire point of the submission is the *reproducible three-VM deployment*, not the feature set. A user browses a seeded anime catalogue, adds new entries by searching the AniList GraphQL API from the browser, and updates/deletes records with an episodes-watched counter and a watch status.

The stack is **Java 17 + Jooby 3 (Netty) + JDBI3 over PostgreSQL** for the backend, **Vue 3 + Vite 8** for the frontend, **Nginx** as the static host and `/api` reverse proxy, and **Vagrant + VirtualBox** for orchestration. Everything is brought up with a single `vagrant up`, and every part of the topology is hand-provisioned by three shell scripts rather than by configuration management.

The application itself is roughly **400 lines of Java** and **~1,200 lines of Vue/JS**. There are no tests. There is no authentication. There is no connection pooling. These facts matter enormously for the AWS migration plan in Part 2, because the migration is mostly about *replacing the three VMs with managed equivalents* while fixing the handful of shortcuts that only worked because everything was on a trusted private network.

---

## Architecture

### Primary pattern

Classic **three-tier layered architecture**, deployed as three single-purpose virtual machines on a VirtualBox private network (`192.168.56.0/24`). There is no service discovery, no message bus, and no shared state other than PostgreSQL. The tiers communicate over plain HTTP with **no TLS** and **no auth token of any kind** — the private network *is* the trust boundary.

```
┌──────────────────────────────────────────────────────────────────┐
│  HOST (Windows/Ubuntu/macOS)                                     │
│                                                                  │
│  localhost:8080 ──► ┌─────────────────────────────┐              │
│                     │  anime-web  192.168.56.12   │              │
│                     │  Nginx :80                  │              │
│                     │   • serves /var/www/anitracker (Vue dist)  │
│                     │   • location /api/ ──┐      │              │
│                     └──────────────────────┼──────┘              │
│                                            │ proxy_pass          │
│                     ┌──────────────────────▼──────┐              │
│  localhost:8081 ──► │  anime-api  192.168.56.11   │              │
│                     │  Jooby/Netty :8080          │              │
│                     │   • /health /anime ...      │              │
│                     └──────────────────────┬──────┘              │
│                                            │ JDBC (no pool)      │
│                     ┌──────────────────────▼──────┐              │
│  localhost:5433 ──► │  anime-db   192.168.56.10   │              │
│                     │  PostgreSQL :5432           │              │
│                     │   • anitracker DB           │              │
│                     └─────────────────────────────┘              │
└──────────────────────────────────────────────────────────────────┘
```

### The critical path-prefix detail

The backend **never sees `/api`**. The prefix exists only as a proxy artifact, stripped twice over:

- Nginx: `location /api/ { proxy_pass http://192.168.56.11:8080/; }` — the **trailing slash on `proxy_pass`** is what strips `/api`.
- Vite dev server: `rewrite: (path) => path.replace(/^\/api/, '')` does the same thing for `npm run dev`.

So the backend's real contract is `GET /anime`, `GET /health`, etc. — **not** `/api/anime`. Any AWS design that routes `/api/*` to the backend must reproduce this rewrite, or the frontend's `apiLinks.API_ANIME = "/api/anime"` breaks. This is the single most commonly-missed migration detail in this repo.

### Technology stack

| Layer | Technology | Version | Notes |
|---|---|---|---|
| Backend runtime | Java | 17 | `sourceCompatibility = VERSION_17` |
| Backend HTTP | Jooby (`jooby-netty`) | 3.1.0 | Netty-backed, annotation-free routing |
| Backend JSON | Jooby Jackson module | 3.1.0 | Serialises Java beans directly |
| DB access | JDBI3 (`core` + `sqlobject`) | 3.45.1 | Declarative SQL-object DAO |
| JDBC driver | `org.postgresql:postgresql` | 42.7.4 | |
| Build | Gradle (wrapper) | **9.5.1** | `application` plugin, `installDist` |
| Database | PostgreSQL | distro default (Ubuntu 22.04 → PG 14) | custom `watch_status` enum |
| Frontend | Vue | ^3.5.40 | `<script setup>` SFCs throughout |
| Frontend routing | vue-router | ^4.3.0 | `createWebHistory` (HTML5 history mode) |
| Frontend build | Vite | ^8.1.5 | + `@vitejs/plugin-vue` ^6.0.8, `vite-plugin-vue-devtools` ^8.1.5 |
| Frontend host | Nginx | distro default | static + reverse proxy |
| Orchestration | Vagrant | 2.4+ | box `ubuntu/jammy64` |
| Hypervisor | VirtualBox | 7.x | 2048 MB / 2 vCPU per VM |
| Node (build-time only) | Node.js | 22.x via NodeSource | `engines: ^22.18.0 \|\| >=24.12.0` |

### How execution starts

**Backend.** `build.gradle` declares `mainClass = 'app.AnimeTrackerApp'` and `applicationName = 'anitracker'`. `./gradlew installDist` produces:

```
build/install/anitracker/bin/anitracker        ← the launch script systemd runs
build/install/anitracker/lib/*.jar
```

`AnimeTrackerApp.main()` calls `Jooby.runApp(args, AnimeTrackerApp::new)`. The **constructor does all wiring** — this is a Jooby idiom worth understanding:

1. `install(new JacksonModule())`
2. Read `DB_URL` / `DB_USER` / `DB_PASSWORD` from `System.getenv()` with hardcoded VM-IP fallbacks
3. `Jdbi.create(dbUrl, dbUser, dbPassword)` — **one Jdbi instance for the process lifetime**
4. `jdbi.installPlugin(new SqlObjectPlugin())`
5. `jdbi.onDemand(AnimeJdbiDAO.class)` — a lazily-generated DAO proxy
6. Register the six routes

Because the constructor does the Jdbi setup, **the process fails fast at boot if the JDBC URL is malformed**, but *does not* fail fast if PostgreSQL is unreachable — `Jdbi.create` only builds a connection factory. That is why `api_provision.sh` needs an `ExecStartPre` `pg_isready` loop *and* a `curl /health` retry loop: the service will happily start with a dead database.

**Frontend.** `frontend/index.html` loads `/src/main.js`, which does `createApp(App).use(router).mount('#app')`. The router (`createWebHistory`) has exactly two routes: `/` → `Main.vue`, `/anime/:id` → `DetailPage.vue`.

**Provisioning.** `Vagrantfile` defines three named machines, each with a static private IP, a forwarded host port, and a single `shell` provisioner pointing at `provision/*.sh`. Provisioning is **not idempotent-by-design** — it's written defensively (IF NOT EXISTS guards, `grep -q` checks) but relies on `set -euo pipefail` to abort on any failure.

---

## Directory Structure

```
Internet_Movie_Database/
├── README.md                    — 13-section deployment/verification runbook (the primary spec)
├── Vagrantfile                  — THE topology definition: 3 VMs, IPs, ports, provisioners
├── build.gradle                 — Java 17, Jooby/JDBI deps, sourceSets remap, mainClass
├── settings.gradle              — rootProject.name = 'Anitracker'
├── gradlew / gradlew.bat        — Gradle 9.5.1 wrapper scripts
├── gradle/wrapper/
│   └── gradle-wrapper.properties — distributionUrl → gradle-9.5.1-bin.zip
├── schema.sql                   — watch_status enum + my_anime + episode_notes tables
├── seed_data.sql                — 18-row idempotent catalogue upsert (ON CONFLICT DO UPDATE)
├── package.json                 — ⚠ STRAY/BROKEN root npm manifest (see Non-Obvious Behaviours)
│
├── provision/                   — the three VM recipes; THIS is what Terraform replaces
│   ├── db_provision.sh          — install PG, create role+db, open pg_hba to 192.168.56.0/24,
│   │                              apply schema+seed, GRANT to app_user, write /etc/profile.d env
│   ├── api_provision.sh         — install JDK17, copy build tree to /opt/anitracker,
│   │                              ./gradlew installDist, write+enable systemd unit, health-gate
│   └── web_provision.sh         — install nginx + Node 22, npm ci && npm run build,
│                                  copy dist → /var/www/anitracker, write nginx site, health-gate
│
├── backend/src/main/app/        — ⚠ note: NOT src/main/java (sourceSets remap)
│   ├── AnimeTrackerApp.java     — Jooby app: wiring, all 6 routes, all validation
│   ├── Anime.java               — the single DTO/entity bean (8 fields)
│   ├── AnimeDAO.java            — ⚠ DEAD INTERFACE — declared, never implemented or injected
│   ├── AnimeJdbiDAO.java        — the real DAO: @SqlQuery/@SqlUpdate + @RegisterBeanMapper
│   └── WatchStatus.java         — enum whose values carry their own DB string
│
├── frontend/
│   ├── package.json             — Vue 3.5 / Vite 8 / Node 22+
│   ├── vite.config.js           — @ alias, dev proxy /api → 192.168.56.11:8080, polling watch
│   ├── jsconfig.json            — @/* → ./src/* (IDE path mapping)
│   ├── index.html               — #app mount + #modal teleport target; Google Fonts
│   ├── public/favicon.ico
│   └── src/
│       ├── main.js              — createApp().use(router).mount('#app')
│       ├── App.vue              — provides watchStatusLabels/apiLinks/apiQueries; <RouterView>
│       ├── router/index.js      — the 2 routes
│       ├── helpers/
│       │   ├── apiStuff.js      — API_ANIME "/api/anime", AniList URL + GraphQL query text
│       │   └── watchStatusLabels.js — the 5 status strings (duplicated from Java enum)
│       ├── api/                 — ⚠ EMPTY DIRECTORY (abandoned refactor)
│       ├── assets/              — AddIcon, LoadingSpinner, Logo, WarningIcon, styles.css (CSS vars)
│       └── views/
│           ├── Main.vue         — catalogue grid + Add modal (AniList search → POST)
│           ├── DetailPage.vue   — fetch/PUT/DELETE one entry, banner + synopsis
│           └── components/      — ModalGeneric, ErrorMsg, StatusBadge, MiniProgressBar,
│                                  EpisodesAndStatusFormSection, MainNav, spinners
│               ├── search/      — SearchBarGeneric, SearchResult
│               └── card_templates/ — CardShowGrid, CardShowTemplate
│
├── src/test/java/               — ⚠ EMPTY. No tests exist.
├── bin/, build/                 — stale IDE/build output (gitignored, present on disk)
└── graphify-out/                — ⚠ COMMITTED code-graph artifact (~237 nodes) — NOT gitignored
```

---

## Key Abstractions

### `AnimeTrackerApp`
- **File**: `backend/src/main/app/AnimeTrackerApp.java`
- **Responsibility**: The entire HTTP surface. Extends `Jooby`; the constructor installs modules, builds the JDBI stack, and registers every route as a lambda. It also owns all **input validation** and **business-rule normalisation**.
- **Interface** (routes):

| Method | Path | Behaviour |
|---|---|---|
| `GET` | `/health` | Runs `SELECT 1`. Returns `{status, database, service}`. **200** on success; **503** `{"status":"error","database":"unavailable"}` on any `RuntimeException`. |
| `GET` | `/anime` | `animeDao.getAllAnime()` → JSON array ordered by `mal_id`. **No pagination.** |
| `GET` | `/anime/{malId}` | **200** with the bean, or **404** `{"error":"Anime not found"}`. |
| `POST` | `/anime` | Validates body → normalises counts → `addAnime` → re-reads and returns the row. **200**, not 201. |
| `PUT` | `/anime/{malId}` | 400 if body null; 400 on malId mismatch (only when body's `malId != null`); 400 on validation failure; 404 if the row doesn't exist; otherwise updates and returns the fresh row. |
| `DELETE` | `/anime/{malId}` | **204** with empty body on success, **404** if `rowsAffected == 0`. |

- **Static helpers**: `healthResponse(status, dbStatus)`, `errorResponse(msg)` (both return immutable `Map.of`), `validateAnime(Anime)` → `String | null`, `normalizeEpisodeCounts(Anime)`.
- **Lifecycle**: One instance per JVM, created by `Jooby.runApp` at boot, never destroyed.
- **Used by**: Nginx (via proxy), the provisioning health gates, and `curl` in the README's verification section.

### `Anime`
- **File**: `backend/src/main/app/Anime.java`
- **Responsibility**: Doubles as **JSON wire DTO** (marshalled by Jackson) and **DB row** (mapped by JDBI's bean mapper). Eight fields: `malId`, `title`, `totalEpisodes`, `episodesWatched`, `watchStatus`, `coverImageUrl`, `backgroundImageUrl`, `synopsis`.
- **The subtle part**: `watchStatus` is stored internally as a `WatchStatus` enum but **exposed as a `String`**. The getter returns `watchStatus.getDatabaseValue()`; the setter parses an incoming string and **silently swallows `IllegalArgumentException` by setting the field to `null`**. Invalid statuses therefore never throw — they become `null`, which `validateAnime` then reports as `"watchStatus is invalid."` This two-stage error funnel is deliberate but easy to miss.
- **Used by**: `AnimeTrackerApp` (all routes), `AnimeJdbiDAO` (via `@RegisterBeanMapper`).

### `AnimeJdbiDAO`
- **File**: `backend/src/main/app/AnimeJdbiDAO.java`
- **Responsibility**: The only live data-access object. Annotated `@RegisterBeanMapper(Anime.class)` at the interface level, so JDBI's reflective bean mapper converts result-set columns to bean properties using **snake_case → camelCase** (`watch_status` → `watchStatus`, `cover_image_url` → `coverImageUrl`). This works only because the column names are exactly snake_case of the property names — adding a column like `coverImg` would silently map to nothing.
- **Notable SQL**: both `INSERT` and `UPDATE` use `CAST(:watchStatus AS watch_status)` to convert the bound `String` into the PostgreSQL enum type. `watch_status` is an **enum whose values contain spaces and hyphens** (`'On-Hold'`, `'Plan to Watch'`) — that's why the Java enum exists at all.
- **No `@Transaction`**, no batch, no connection pool handling.
- **Used by**: `AnimeTrackerApp` only, via `jdbi.onDemand(...)`.

### `WatchStatus`
- **File**: `backend/src/main/app/WatchStatus.java`
- **Responsibility**: A five-value enum where each constant carries its database string: `WATCHING("Watching")`, `COMPLETED("Completed")`, `ON_HOLD("On-Hold")`, `DROPPED("Dropped")`, `PLAN_TO_WATCH("Plan to Watch")`.
- **Critical invariant**: these five strings must match the `watch_status` PostgreSQL enum in `schema.sql` **character-for-character, including the hyphen and spaces**. They must *also* match the JS object in `frontend/src/helpers/watchStatusLabels.js`. **The status vocabulary is triplicated across three files in two languages with no test or codegen keeping them in sync.** Changing a label requires editing three files.
- `fromValue(String)` throws on unknown input; `toString()` returns the DB value.

### `AnimeDAO`
- **File**: `backend/src/main/app/AnimeDAO.java`
- **Responsibility**: Nothing. It is an **abstract DAO interface with zero implementation and zero call sites**. `AnimeTrackerApp` uses `AnimeJdbiDAO` directly. It also uniquely declares `getAnimeByTitle(String)`, which `AnimeJdbiDAO` happens to implement and nobody calls. This is leftover from an earlier design and is dead code — safe to delete during migration.

### `apiLinks` / `apiQueries` (frontend)
- **File**: `frontend/src/helpers/apiStuff.js`
- **Responsibility**: Frozen config objects for the two outbound HTTP dependencies. `apiLinks.API_ANIME = "/api/anime"` (relative, same-origin → proxied), `apiLinks.ANILIST_API = "https://graphql.anilist.co"` (absolute, **called directly from the browser**).
- **Injected** in `App.vue` via `provide()` and consumed with `inject()` in `Main.vue` and `DetailPage.vue`. This is the app's only DI mechanism.
- **Migration significance**: because `API_ANIME` is *relative*, the only thing pinning the API location is the Nginx/Vite proxy. Pointing the frontend at a different API origin is a one-constant change — but that change immediately introduces **CORS**, which the backend does not implement.

### `Main.vue`
- **File**: `frontend/src/views/Main.vue`
- **Responsibility**: The catalogue view and the create flow. On mount, `fetchAnimeData()` calls `GET /api/anime`. The Add modal does a two-phase create: first `searchAnime(query)` POSTs a GraphQL query to AniList (browser → AniList directly, bypassing the backend entirely), then a `watch` on `selectedNewAnimeToAdd` copies the chosen AniList media object into `newAnimeData` and `addAnime()` POSTs it to `/api/anime`.
- **Field mapping AniList → schema**: `idMal`→`malId`, `title.english || title.romaji`→`title`, `episodes`→`totalEpisodes`, `0`→`episodesWatched`, `'Plan to Watch'`→`watchStatus`, `coverImage.extraLarge || coverImage.large`→`coverImageUrl`, `bannerImage`→`backgroundImageUrl`, `description`→`synopsis`.
- **Latent bug**: `addAnime()`'s `finally` block sets `isSearchDisabled.value = true` (should almost certainly be `isAddDisabled`). Closing the modal triggers `resetForm()` which sets it back to `false`, but ordering means the search button can be left disabled — and `isAddDisabled` is never assigned anywhere in the file, so the Add button's `:disabled` binding depends entirely on the other four conditions.

### `DetailPage.vue`
- **File**: `frontend/src/views/DetailPage.vue`
- **Responsibility**: Read/update/delete a single entry. A `watch` on `route.params.id` with `{ immediate: true }` builds `apiAnimeIdLink = "/api/anime/" + id` and fetches — this **doubles as `onMounted`**, a deliberate pattern worth noting.
- **Behaviour**: `origAnimeData` holds a shallow clone for "reset changes" on modal dismiss; `isUpdating` is the flag that suppresses that reset after a successful save.
- **Security note**: the synopsis is rendered with `v-html`. The content originates from the AniList API (`description`), so this is an XSS sink fed by third-party data. Low risk in a demo, unacceptable in production.

### `EpisodesAndStatusFormSection.vue`
- **File**: `frontend/src/views/components/EpisodesAndStatusFormSection.vue`
- **Responsibility**: The status ↔ episode-count coupling, implemented as **two mutually-observing watchers**:
  - `watch(animeData.watchStatus)`: `Completed` → `episodesWatched = totalEpisodes`; `Plan to Watch` → `episodesWatched = 0`.
  - `watch(animeData.episodesWatched)`: if it equals `totalEpisodes` → `watchStatus = 'Completed'`.
- This is the app's most subtle client-side logic and it runs in **both** the Add modal (new entries) and the Detail update modal. Note the asymmetry the backend enforces: `normalizeEpisodeCounts` clamps `episodesWatched` down to `totalEpisodes`, but the frontend watcher only flips status **up** to Completed — it never flips it back down.

### `Vagrantfile`
- **File**: `Vagrantfile`
- **Responsibility**: The entire deployment topology. Three `config.vm.define` blocks. Also sets `config.ssh.insert_key = false` and points at the insecure Vagrant RSA key — a convenience that makes provisioning scriptable but is exactly the kind of thing that must vanish in AWS.
- **This file is the direct analogue of everything Terraform will define in Part 2.** Every line has a managed-AWS counterpart.

---

## Data Flow

### Read path — catalogue page
1. Browser → `http://localhost:8080/` → Nginx on **web VM**, `root /var/www/anitracker`, `try_files $uri $uri/ /index.html`.
2. `index.html` loads the Vite bundle → `main.js` → `App.vue` provides `apiLinks` → router mounts `Main.vue`.
3. `onMounted` → `fetchAnimeData()` → `fetch("/api/anime")` (relative → same origin).
4. Nginx `location /api/` matches; `proxy_pass http://192.168.56.11:8080/` **strips `/api`** → request arrives at **api VM** as `GET /anime`.
5. Jooby route lambda calls `animeDao.getAllAnime()` → JDBI opens a **new JDBC connection via `DriverManager`** → `SELECT * FROM my_anime ORDER BY mal_id` on **db VM**.
6. JDBI's bean mapper converts each row; Jackson serialises the `List<Anime>` (with `watchStatus` rendered as its DB string via the getter) to JSON.
7. Response flows back through Nginx unmodified. `Main.vue` assigns it to `animeList` and renders `CardShowGrid` → `CardShowTemplate` → `RouterLink :to="/anime/${malId}"`.

### Create path — adding an anime from AniList
1. User clicks **Add** → `showAddModal = true` → `ModalGeneric` teleports into `#modal`.
2. User types a title and hits Enter → `SearchBarGeneric` emits `search` → `Main.vue.searchAnime(query)`.
3. **Browser → `https://graphql.anilist.co` POST** with `ANILIST_SEARCH_BY_TITLE` and `variables.search`. *The backend is not involved.* GraphQL-level errors are read from `result.errors[0]` before checking `response.ok` — a deliberate ordering choice.
4. Results render in `SearchResult.vue` (a multi-select over `resultData.data?.Page?.media`). Selecting one triggers the `selectedNewAnimeToAdd` watcher, which maps the AniList object onto the schema shape.
5. Submit → `addAnime()` → `POST /api/anime` with the mapped body.
6. Backend: Jackson deserialises into `Anime` (the `watchStatus` setter parses the string) → `validateAnime` → `normalizeEpisodeCounts` → `INSERT ... CAST(:watchStatus AS watch_status)` → re-read the row → **200** with the persisted bean.
7. Frontend closes the modal and calls `fetchAnimeData()` again — **a full catalogue refetch rather than a local append.**

### Update / delete path
1. `DetailPage` fetches `GET /api/anime/{id}`; on 404 the UI shows `ErrorMsg`.
2. Update: modal → `PUT /api/anime/{id}` with the whole bean as the body. Backend checks body/URL `malId` agreement, validates, verifies existence (**an extra `SELECT` per update**), then `UPDATE`.
3. Delete: `DELETE /api/anime/{id}` → 204 → `redirect.push('/')`.

### Health / readiness flow
1. `db_provision.sh` polls `pg_isready` up to 30× 1 s after restarting PostgreSQL.
2. `api_provision.sh`'s systemd unit has `ExecStartPre` polling `pg_isready` for **60× 1 s**, then the script polls `curl /health` for **30× 2 s**.
3. `web_provision.sh` polls `curl http://192.168.56.11:8080/health` for **60× 2 s** before starting Nginx.
4. Fault-injection ordering is explicit: **db → api → web**. Every step gates on the previous one's health endpoint. This is a hand-rolled distributed readiness protocol — and on AWS, **ECS container health checks, target-group health checks, and RDS creation ordering replace all of it.**

---

## Non-Obvious Behaviours & Design Decisions

### Hidden invariants

1. **The status vocabulary is triplicated.** `schema.sql` (`CREATE TYPE watch_status AS ENUM`), `WatchStatus.java`, and `watchStatusLabels.js` must agree exactly. `'On-Hold'` has a hyphen; `'Plan to Watch'` has spaces. A single character of drift produces a `CAST` failure at `INSERT` time and a silently-null `watchStatus` at parse time.

2. **Column names must be exact snake_case of bean properties.** `@RegisterBeanMapper` has no explicit column mapping. `background_image_url` → `backgroundImageUrl` works by convention only.

3. **`watch_status` is a real PostgreSQL enum, not a VARCHAR.** This is unusual and consequential — it cannot be altered freely (adding a value needs `ALTER TYPE ... ADD VALUE`, which pre-PG12 couldn't run in a transaction). It also means the seed file's `ON CONFLICT ... DO UPDATE SET watch_status = EXCLUDED.watch_status` relies on the excluded value already being a valid enum literal.

4. **The backend has no `/api` prefix.** The prefix exists only in Nginx and Vite. See the path-prefix note above.

5. **The frontend must be served with SPA fallback.** `createWebHistory` means `/anime/52991` is a *client-side* route. Nginx's `try_files ... /index.html` handles it. **Without an equivalent fallback, a browser refresh on a detail page 404s.**

### Why odd things are the way they are

- **Jooby + JDBI rather than Spring Boot.** Minimal dependency surface, fast startup, no annotation scanning — appropriate for a two-hour provisioning budget and gives `installDist` a tiny output the provisioning script can copy wholesale.
- **`sourceSets` remap to `backend/src/main`.** The repo keeps frontend and backend as sibling directories at the root, so the non-standard `srcDirs = ['backend/src/main']` is required. **This means `build.gradle`, `settings.gradle`, and the `backend/` directory must always sit at the same relative paths** — a fact that directly dictates how the Docker build context must be laid out.
- **Static AniList seed data instead of runtime metadata fetching.** `seed_data.sql` ends with an explicit rationale comment:
  > *"To prevent external API rate-limits and 504 Gateway timeouts during automated builds, anime metadata was structured into a static SQL seed file... Since Jikan happens to be down a lot of the time we don't use it and just have a seed instead."*

  This is the most important design decision in the repo: **the server never calls AniList.** AniList is called only by the *browser* during interactive user search. The backend therefore has **zero third-party runtime dependencies** — which makes it trivially containerisable and removes any need for NAT-gateway egress or VPC endpoints for external APIs in the AWS design. The README's §12 explicitly notes there is no `502` path for AniList enrichment because "that behavior is currently not enabled."
- **`ON CONFLICT (mal_id) DO UPDATE` in the seed.** The seed is a true **idempotent upsert**, so `vagrant provision db` can be re-run repeatedly. This is what makes the migration reproducible and is why re-running the seed on RDS is safe.
- **Defensive shell provisioning.** Every script uses `set -euo pipefail` (web uses `-x` too); role/db creation is guarded by `SELECT 1 FROM pg_roles` / `psql -lqt` checks; config appends are guarded by `grep -q`. The scripts are written to survive a second run.
- **Node 22 pinned via NodeSource**, not Ubuntu's `apt` Node. Ubuntu 22.04 ships Node 12/18; Vite 8 requires ≥ 22.18. The NodeSource bootstrap is a hard requirement.

### State management

The application is **almost entirely stateless**. Mutable state exists in exactly four places:

| State | Where | Mutated by | Lifetime |
|---|---|---|---|
| `my_anime` rows | PostgreSQL on db VM | `AnimeJdbiDAO` INSERT/UPDATE/DELETE | Persistent (the only durable state) |
| Jdbi instance + DAO proxy | `AnimeTrackerApp` constructor | Never (immutable after construction) | Process |
| `animeList`, `newAnimeData`, `searchResults`, modal booleans | `Main.vue` / `DetailPage.vue` `ref()`s | User interaction + `fetch` responses | Component |
| `apiLinks` / `apiQueries` / `watchStatusLabels` | `App.vue` `provide()` | Never (`Object.freeze`) | App |

Consequences: the API is **horizontally scalable with zero session affinity** — this is a genuinely important property for the ECS/Fargate plan. There is no cache, no queue, and no cron. **A `watch_status` value written by one instance is immediately visible to all others, because PostgreSQL is the only shared state.**

### Error propagation

Three distinct, disconnected error strategies:

1. **Java — thrown exceptions escape to Jooby's default handler.** `AnimeTrackerApp` has **no error handler installed** and no `try/catch` around the route bodies (except `/health`). Every deliberate error path returns an explicit status + `{"error": ...}` map, but anything *unexpected* — `ctx.path("malId").intValue()` on `/anime/abc`, a `CAST` failure, a JDBI exception — escapes and produces **Jooby's default 500 response, whose body shape the frontend does not parse.** `Main.vue` and `DetailPage.vue` only ever read `response.status`/`response.statusText` for non-2xx, never the `{"error": ...}` body. So the carefully constructed error messages are **effectively invisible to users** — the UI shows `Error 500: Internal Server Error`. The one exception is the AniList GraphQL path, which *does* surface `errors[0].message`.
2. **`/health` swallows.** It catches `RuntimeException` broadly and downgrades to a 503 with a generic message. This is intentional — it's a liveness probe — but it means a DB outage is indistinguishable from a bad query.
3. **Frontend — per-action local `ref('')` strings.** Every fetch has its own `try/catch/finally` writing to a dedicated error ref (`fetchAnimeListErr`, `searchAnimeNameErr`, `newAnimeDataErr`, `deleteErr`, `updateErr`), rendered by `ErrorMsg.vue`. `finally` blocks manage loading/disabled flags. **Nothing is caught globally** — an error thrown outside a `try` would vanish into the console.

**Nothing aborts the process or the task.** There is no worker loop, no job, no retry. Failures are per-request and always return a response.

### Performance-sensitive paths

Very little is optimised — and that itself is a finding:

- **No connection pooling.** `Jdbi.create(url, user, password)` builds a `DriverManager`-based connection factory, so **every DAO call opens and closes a brand-new PostgreSQL connection** (TCP handshake + auth + backend process spawn). On a LAN VM this costs a few milliseconds. **On RDS it becomes the single biggest performance and reliability problem**: it multiplies auth round trips, will blow through `max_connections` under modest concurrency, and adds TLS handshake cost if `sslmode=require` is enabled. **Adding HikariCP (`jdbi3` + `HikariDataSource` wired into `Jdbi.create(ds)`) is effectively mandatory for the AWS migration.** This is the highest-value code change in the whole plan.
- **`GET /anime` has no pagination, filtering, or index beyond the PK.** 18 rows today; the JSON response is the whole table. The seed's `ORDER BY mal_id` uses the primary key index, so it's fine at this size, but the pattern does not scale.
- **`POST` and `PUT` both do a write followed by a read.** `addAnime` then `getAnimeByMalId`; `updateAnime` then `getAnimeByMalId` — plus `PUT` does an additional existence `SELECT` first. **Three round trips for an update.** Deliberate (it guarantees the response reflects DB defaults/normalisation) but wasteful.
- **`addAnime` on the frontend refetches the entire catalogue** instead of appending locally.
- **No HTTP compression, no caching headers, no CDN.** Nginx serves uncompressed static assets with default caching. CloudFront fixes this for free.

### External dependencies and their quirks

- **AniList GraphQL (`https://graphql.anilist.co`)** — the one external API, called **only from the browser** and **only during interactive search**. Quirks the code already handles: GraphQL errors arrive with HTTP 200, so `result.errors` must be inspected before trusting `response.ok`; `title.english` may be `null` while `romaji` is not; `episodes` is `null` for ongoing series (`SearchResult.vue` renders "Ongoing"); `coverImage.extraLarge` may be absent. **AniList applies per-IP rate limiting and does not send permissive CORS headers for non-browser origins** — irrelevant here because the call is browser-origin, but it means "move the AniList call to the backend" is *not* a free refactor.
- **PostgreSQL enum type** — the `DO $$ ... $$` block in `schema.sql` guards enum creation, since `CREATE TYPE ... IF NOT EXISTS` does not exist for enums.
- **Google Fonts** — `index.html` preconnects to `fonts.googleapis.com` / `fonts.gstatic.com`. Four families are requested (`Noto Sans Tagalog`, `Raleway`, `Space Grotesk`, plus italics). **A default-src CSP would break the UI**, and this is a third-party runtime dependency that CloudFront cannot cache — worth noting if hardening is in scope.
- **VirtualBox + Hyper-V on Windows** — the README warns that a turtle icon means Hyper-V is enabled and provisioning will stall. `vite.config.js` sets `usePolling: true` because VirtualBox shared folders don't emit reliable inotify events — **this polling setting should be removed in the AWS/container build** (it's a dev-only workaround that burns CPU).

### The stray root `package.json` — a real defect

The repository root contains a `package.json` declaring `{"dependencies": {"vue-router": "^5.3.0"}}` plus a matching `package-lock.json`. **This is broken and should be deleted as part of the migration:**

- `vue-router@5.3.0` **does not exist** — the real versions are 4.x. The frontend correctly pins `^4.3.0`.
- The file has no `name`, no `scripts`, no `private` flag, and lists a *runtime* dependency at a repo root that has no JS source.
- Combined with `frontend/package.json`, a Docker build or CI job doing a root-level `npm install` will fail or install garbage.

It is dead weight from an earlier layout. Its presence also means **any recursive `npm ci` in a Dockerfile or CI workflow must be scoped explicitly to `frontend/`.**

### Other things the code doesn't explain about itself

- **No authentication or authorisation anywhere.** Every endpoint is world-readable and world-writable. The private Vagrant network is the entire security model. On AWS this must be addressed before the app is publicly reachable.
- **Credentials are hardcoded in at least five places**: `db_provision.sh` (role creation), `db_provision.sh` (the `/etc/profile.d` env file), `api_provision.sh` (systemd `Environment=` lines), `AnimeTrackerApp.java` (all three `getOrDefault` fallbacks), and the README's verification commands. `AppPass123` / `app_user` is committed to git history. **Rotating it is not optional** — and note that `git rm` alone will not remove it from history.
- **Dead config**: `db_provision.sh` writes `/etc/profile.d/anitracker-db-env.sh` exporting `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` — but the backend reads **`DB_URL`** (a full JDBC string), `DB_USER`, `DB_PASSWORD` from systemd, which is a *different* set of names. `DB_HOST`/`DB_NAME` are read by nothing. The `/etc/profile.d` file is purely informational for humans who SSH in.
- **Two unused/scaffolded directories**: `frontend/src/api/` is empty and `src/test/java/` is empty. Both suggest an abandoned refactor and a test suite that was never written.
- **`graphify-out/` is committed and not gitignored.** It contains a generated `graph.json`, `graph.html`, `GRAPH_REPORT.md`, and a full AST cache under `graphify-out/cache/ast/`. It's ~15+ files of build artifact that will be copied into any naive Docker build context and inflate it. Add it to `.gitignore` and `.dockerignore`.
- **`bin/` and `build/`** are present on disk but correctly gitignored — leftovers from an Eclipse/NetBeans import.
- **The `Vagrantfile` disables SSH key insertion** and points at the well-known insecure Vagrant private key. Convenient for scripting; a finding for any audit.
- **`gradle-wrapper.properties` pins Gradle 9.5.1 while the build targets Java 17.** That combination is fine, but note the base image for a Docker build must be ≥ JDK 17 and the wrapper will download a ~130 MB distribution at build time unless cached.
- **`watchStatusLabels.js` in the frontend exports the same five strings as `WatchStatus.java`** — and `Anime.getWatchStatus()` returns `watchStatus.getDatabaseValue()`, so the *wire format* is the human-readable string (`"Plan to Watch"`), not the enum name (`PLAN_TO_WATCH`). Any client must speak the display strings.

---

## Module Reference

| File | Purpose |
|---|---|
| `Vagrantfile` | **The deployment spec.** 3 VMs, static IPs, host port forwards, provisioner wiring, insecure-key config. The direct analogue of everything Terraform will generate. |
| `provision/db_provision.sh` | Installs PostgreSQL, creates `app_user`/`anitracker`, opens `pg_hba` to `192.168.56.0/24`, applies `schema.sql` + `seed_data.sql`, grants table/sequence privileges and default privileges, writes a (largely unused) `/etc/profile.d` env file. |
| `provision/api_provision.sh` | Installs OpenJDK 17 + `postgresql-client`, copies the Gradle tree to `/opt/anitracker`, runs `./gradlew clean installDist`, writes and enables the `anitracker-api.service` systemd unit (with `DB_URL`/`DB_USER`/`DB_PASSWORD` and a `pg_isready` `ExecStartPre`), then health-gates on `curl /health`. |
| `provision/web_provision.sh` | Installs Nginx + Node 22 (NodeSource), `npm ci && npm run build` in `/tmp/anitracker-frontend`, copies `dist/` → `/var/www/anitracker`, writes the `anitracker` Nginx site (SPA fallback + `/api` proxy to `192.168.56.11:8080`), disables the default site, health-gates on the API, reloads Nginx. |
| `schema.sql` | `DO $$`-guarded `watch_status` enum; `my_anime` (PK `mal_id`, 7 more columns, `episodes_watched DEFAULT 0`, `watch_status DEFAULT 'Plan to Watch'`); `episode_notes` (unused, FK cascade to `my_anime`). |
| `seed_data.sql` | 18 anime rows as a single `INSERT ... ON CONFLICT (mal_id) DO UPDATE` upsert — idempotent and re-runnable. Carries the rationale comment for why metadata is static. |
| `build.gradle` | Java 17, Maven Central, 5 dependencies, **`sourceSets` remap to `backend/src/main`**, `applicationName='anitracker'`, `mainClass='app.AnimeTrackerApp'`, UTF-8 compile encoding. |
| `settings.gradle` | `rootProject.name = 'Anitracker'` — determines the `installDist` directory name. |
| `gradle/wrapper/gradle-wrapper.properties` | Pins Gradle 9.5.1. |
| `backend/src/main/app/AnimeTrackerApp.java` | The whole HTTP API: wiring, JDBI setup, 6 routes, validation, normalisation, `/health` liveness probe. |
| `backend/src/main/app/Anime.java` | The single bean: JSON DTO *and* JDBI-mapped row. Enum↔String adaptation lives in the `watchStatus` accessors. |
| `backend/src/main/app/AnimeJdbiDAO.java` | The only live DAO — 5 SQL-object methods, `@RegisterBeanMapper`, `CAST(:watchStatus AS watch_status)`. |
| `backend/src/main/app/AnimeDAO.java` | ⚠ Dead interface. No implementation, no call sites. Delete candidate. |
| `backend/src/main/app/WatchStatus.java` | 5-value enum carrying DB strings; the backend half of the triplicated status vocabulary. |
| `frontend/vite.config.js` | `@` alias, `host: 0.0.0.0`, dev proxy `/api` → `192.168.56.11:8080` **with prefix rewrite**, `usePolling: true` (VirtualBox workaround — remove for containers). |
| `frontend/src/App.vue` | Provides `watchStatusLabels`, `apiLinks`, `apiQueries`; renders `MainNav` + `RouterView`. |
| `frontend/src/router/index.js` | Two routes; `createWebHistory` ⇒ **requires server-side SPA fallback**. |
| `frontend/src/helpers/apiStuff.js` | `API_ANIME = "/api/anime"`, AniList URL, and the `ANILIST_SEARCH_BY_TITLE` GraphQL query. The only place the API origin is defined. |
| `frontend/src/helpers/watchStatusLabels.js` | The 5 display strings — must match `WatchStatus.java` and the DB enum. |
| `frontend/src/views/Main.vue` | Catalogue grid, pagination-free fetch, AniList search → create flow, modals, error refs. |
| `frontend/src/views/DetailPage.vue` | Per-entry fetch/PUT/DELETE, `v-html` synopsis sink, route-param-driven lifecycle. |
| `frontend/src/views/components/EpisodesAndStatusFormSection.vue` | The bidirectional status ↔ episodes-watched watchers. |
| `frontend/src/views/components/ModalGeneric.vue` | `defineModel`-driven modal, `Teleport` to `#modal`, click-outside close. |
| `frontend/src/views/components/MiniProgressBar.vue` | `v-bind()`-in-CSS progress width; renders a gradient bar when `totalEpisodes` is null. |
| `frontend/src/views/components/StatusBadge.vue` | Computed class binding for the Completed/Dropped badge colours. |
| `frontend/src/views/components/search/SearchResult.vue` | Multi-select over the AniList response; "Ongoing" for null episodes. |
| `frontend/src/views/components/card_templates/CardShowTemplate.vue` | Poster card → `RouterLink /anime/:malId`. |
| `frontend/src/views/components/card_templates/CardShowGrid.vue` | Grid wrapper over the anime array. |
| `frontend/src/assets/styles.css` | CSS custom properties (`--color-primary`, `--default-border-radius`, …) used app-wide. |

*(Omitted: `AddIcon.vue`, `LoadingSpinner.vue`, `Logo.vue`, `WarningIcon.vue`, `ErrorMsg.vue`, `FullBlockLoadingSpinner.vue`, `MainNav.vue`, `SearchBarGeneric.vue` — presentational/inert. Also omitted: `bin/`, `build/`, `graphify-out/` — generated.)*

---

## Suggested Reading Order

1. **`README.md`** — Read the whole thing first. It is the assignment's actual deliverable and states the topology, ports, verification commands, and the developer redeployment workflow better than any source file. §1 (architecture), §5 (verification), and §8 (modification workflow) are the ones that matter.
2. **`Vagrantfile`** — 40 lines that define the entire system's shape. Read it immediately after the README: everything Terraform must reproduce is here.
3. **`backend/src/main/app/AnimeTrackerApp.java`** — The complete backend in one file: routing, validation, DB wiring, health. Once you've read this you know 90% of the server behaviour, including the `DB_URL`/`DB_USER`/`DB_PASSWORD` env contract.
4. **`provision/api_provision.sh`** — Shows how the Java app actually becomes a running service (`installDist` + systemd + env vars). This is the file that most directly tells you what a container image must do.
5. **`provision/web_provision.sh`** — Reveals the Nginx config that the frontend depends on: SPA fallback and the `/api` prefix strip. **Do not skip this if you're migrating** — it's where the path-rewrite gotcha is hiding.
6. **`schema.sql` + `seed_data.sql`** — Together these are the entire data model and the migration payload. The `ON CONFLICT` upsert is what makes a re-run on RDS safe.
7. **`frontend/src/views/Main.vue`** — The busiest frontend file; shows both the API contract (`/api/anime`) and the AniList browser-direct integration.
8. **`frontend/src/views/DetailPage.vue`** — The remaining three HTTP verbs and the SPA-route-refresh dependency.

Then, for the migration specifically: **`build.gradle`** (the `sourceSets` remap dictates the Docker build context), **`frontend/vite.config.js`** (the dev proxy marks what production must replicate), and **`frontend/src/helpers/apiStuff.js`** (the single API-origin constant).
---

# PART 2 — AWS Migration Plan

## 2.1 Migration thesis

This is a **near-ideal lift-and-shift candidate**, because the application is stateless, has no message broker, no cache, no scheduled work, no server-side third-party calls, and no session affinity. The three VMs map almost 1:1 onto managed AWS services:

| Current VM | Role | AWS replacement | Change risk |
|---|---|---|---|
| `anime-db` (192.168.56.10) | PostgreSQL 14 | **Amazon RDS for PostgreSQL** | **Low** — wire-compatible; needs SSL + enum creation + non-superuser-aware grants |
| `anime-api` (192.168.56.11) | Jooby/Netty on :8080 | **ECS Fargate service behind an ALB** (or App Runner) | **Low** — needs a Dockerfile, HikariCP, and env-var injection |
| `anime-web` (192.168.56.12) | Nginx static + `/api` proxy | **S3 + CloudFront** (recommended) *or* a second Fargate + nginx service | **Medium** — the `/api` prefix strip and SPA fallback must be reproduced exactly |
| Vagrant + VirtualBox | Provisioning | **Terraform** (`hashicorp/aws`) | This *is* the deliverable |

**Two code changes are effectively mandatory**, and both are small:

1. **Add connection pooling (HikariCP).** The current `Jdbi.create(url, user, pass)` opens a fresh `DriverManager` connection per DAO call. Against RDS this exhausts `max_connections` and adds a TCP + auth (+ TLS) round trip to every single request — including `/health`.
2. **Remove the hardcoded DB fallbacks** in `AnimeTrackerApp.java`. They already read `System.getenv()`, so the *contract* is right; the *defaults* will silently point a misconfigured ECS task at `192.168.56.10`, an RFC1918 address that does not exist inside the VPC.

**One code change is strongly recommended:** add a Jooby `errorHandler` that returns the same `{"error": ...}` JSON shape the deliberate error paths already use. Today every unexpected exception yields Jooby's default 500 body, and the frontend discards it.

Everything else — **including the `/api` prefix** — can be handled entirely in infrastructure.

## 2.2 Target architecture

```
                                ┌──────────────┐
    Internet ──► Route 53 ──►   │  CloudFront  │  (ACM cert in us-east-1, HTTPS, optional WAF)
                     anitracker.example.com     └──────┬───────┘
                                                      │
                        ┌─────────────────────────────┴──────────────────────────┐
                        │                                                        │
              default behavior /*                                     behavior /api/*
                        │                                                        │
              ┌─────────▼─────────┐                                 ┌────────────▼─────────────┐
              │   S3 (private)    │                                 │  CloudFront Function     │
              │  Vue build output │                                 │  rewrite /api/* → /*     │
              │  via OAC          │                                 └────────────┬─────────────┘
              └───────────────────┘                                              │
                                                                     ┌───────────▼───────────┐
                                                                     │   ALB (public, 2 AZ)  │
                                                                     │   :443, ACM cert      │
                                                                     │   health check /health│
                                                                     └───────────┬───────────┘
                                                                                 │ :8080
                                                  ┌──────────────────────────────▼──────────────┐
                                                  │  VPC 10.0.0.0/16                            │
                                                  │  public  10.0.0.0/24, 10.0.1.0/24           │
                                                  │  private 10.0.10.0/24, 10.0.11.0/24         │
                                                  │                                             │
                                                  │   ┌─────────────────────────────────┐       │
                                                  │   │ ECS Fargate Service             │       │
                                                  │   │  task: anitracker-api           │       │
                                                  │   │  0.25 vCPU / 0.5 GB, 2 replicas │       │
                                                  │   │  port 8080 · SG: ALB → 8080     │       │
                                                  │   └──────────────┬──────────────────┘       │
                                                  │                  │ 5432 (TLS)              │
                                                  │   ┌──────────────▼──────────────────┐       │
                                                  │   │ RDS PostgreSQL 16               │       │
                                                  │   │ db.t4g.micro · gp3 20 GB        │       │
                                                  │   │ PRIVATE subnets                 │       │
                                                  │   │ SG: task SG → 5432 only         │       │
                                                  │   └─────────────────────────────────┘       │
                                                  └─────────────────────────────────────────────┘
        Secrets Manager ──► ECS task `secrets` ──► DB_USER / DB_PASSWORD
        ECR ──► task image  ·  CloudWatch Logs ──► /ecs/anitracker-api
```

### Why CloudFront + S3 instead of a second Fargate service

The current Nginx VM does **two** jobs: serve static files, and reverse-proxy `/api`. CloudFront + S3 replaces the first for free (with compression and global edge caching, which Nginx never had) and the second via a cache behavior. The alternative — running Nginx in a container — works but costs a second Fargate service and a redundant network hop. **Recommended: CloudFront + S3.**

### The two-AZ rule

RDS requires a **DB subnet group spanning at least two AZs**, even for a Single-AZ instance. So two private subnets are mandatory regardless. Use `ap-southeast-2` (Sydney) or `us-east-1`, with AZs `<region>a` and `<region>b`.

### Fargate networking: public or private?

- **Public subnets + public IP** — cheapest. Saves the **$32+/month NAT gateway**. The security group still blocks everything except ALB→8080, so the task is not reachable from the internet. **Recommended for a coursework deployment.**
- **Private subnets + NAT gateway** — "textbook correct", but adds ~$32/mo plus data processing for a low-traffic app. If full private networking is required, prefer **VPC endpoints** over a NAT gateway: `ecr.api` + `ecr.dkr` (interface), S3 (gateway), CloudWatch Logs, and Secrets Manager.

Whichever you choose, **state the reasoning in the Terraform comments** — a reviewer will ask.

## 2.3 Terraform repository layout

Keep Terraform in the same repo under `infra/` so a single clone still reproduces everything — preserving the "one command from a clean clone" property the README brags about.

```
Internet_Movie_Database/
├── infra/
│   ├── versions.tf              — required_version + provider pins
│   ├── providers.tf             — aws (default region) + aws.us_east_1 alias
│   ├── backend.tf               — S3 remote state + locking
│   ├── variables.tf             — region, project, env, sizing, domain, image_tag
│   ├── locals.tf                — name_prefix, common tags, CIDR maps
│   ├── outputs.tf               — cloudfront_domain, alb_dns, rds_endpoint, api_url
│   ├── main.tf                  — module composition
│   ├── dev.tfvars               — committed, no secrets
│   ├── prod.tfvars              — committed, no secrets
│   └── modules/
│       ├── network/             — VPC, subnets, IGW, route tables, 3 security groups
│       ├── secrets/             — Secrets Manager secret + generated password
│       ├── rds/                 — subnet group, parameter group, instance, alarms
│       ├── ecr/                 — repository + lifecycle policy
│       ├── ecs/                 — cluster, IAM roles, task def, service, log group
│       ├── alb/                 — LB, target group, HTTP→HTTPS listeners
│       ├── static-site/         — S3 + OAC + CloudFront + CF Function
│       └── dns/                 — ACM (us-east-1) + Route 53 validation + alias
├── docker/
│   ├── backend.Dockerfile
│   └── schema-loader.Dockerfile — only if you take the one-off-ECS-task bootstrap path
├── .dockerignore                — NEW, mandatory
└── .github/workflows/
    ├── backend.yml              — build → push ECR → ecs update-service
    ├── frontend.yml             — build → s3 sync → cloudfront invalidation
    └── terraform.yml            — fmt, validate, plan on PR; apply on main
```

### Remote state (create this first)

```hcl
# infra/backend.tf
terraform {
  backend "s3" {
    bucket       = "anitracker-tfstate-<account-id>"
    key          = "anitracker/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true          # Terraform >= 1.10 native S3 locking
    # For Terraform < 1.10 use dynamodb_table = "anitracker-tfstate-lock" instead
  }
}
```

The state bucket must be created **out of band** (a small `bootstrap/` config, or the console) — Terraform cannot manage the bucket that holds its own state. Enable versioning on it; a corrupted state file is otherwise unrecoverable.

### Provider pinning

```hcl
# infra/versions.tf
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws    = { source = "hashicorp/aws",    version = "~> 5.70" }
    random = { source = "hashicorp/random", version = "~> 3.6"  }
    null   = { source = "hashicorp/null",   version = "~> 3.2"  }
  }
}

# infra/providers.tf
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "anitracker"
      Environment = var.env
      ManagedBy   = "terraform"
      Course      = "COSC349"
    }
  }
}

# CloudFront certificates MUST live in us-east-1, regardless of everything else.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
```

## 2.4 Module: `network`

This is the direct translation of the `Vagrantfile`'s `private_network` and `forwarded_port` lines.

```hcl
# infra/modules/network/main.tf
data "aws_availability_zones" "available" { state = "available" }

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr          # 10.0.0.0/16
  enable_dns_support   = true
  enable_dns_hostnames = true                  # REQUIRED for RDS + ECS name resolution
  tags                 = { Name = "${var.name_prefix}-vpc" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)          # 10.0.0.0/24, 10.0.1.0/24
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name_prefix}-public-${count.index + 1}", Tier = "public" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)           # 10.0.10.0/24, 10.0.11.0/24
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = { Name = "${var.name_prefix}-private-${count.index + 1}", Tier = "private" }
}

resource "aws_internet_gateway" "main" { vpc_id = aws_vpc.main.id }

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private subnets deliberately have NO 0.0.0.0/0 route (no NAT gateway).
# RDS needs no egress; the ECS task runs in public subnets to pull from ECR.
resource "aws_route_table" "private" { vpc_id = aws_vpc.main.id }

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

### Three security groups — one per former VM

```hcl
# ALB — the only internet-facing security group
resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  description = "Public entry point; replaces the web VM's forwarded port"
  vpc_id      = aws_vpc.main.id

  ingress { description = "HTTP"  from_port = 80  to_port = 80  protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { description = "HTTPS" from_port = 443 to_port = 443 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }

  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }

  lifecycle { create_before_destroy = true }
}

# ECS tasks — only the ALB may reach :8080
resource "aws_security_group" "ecs" {
  name_prefix = "${var.name_prefix}-ecs-"
  description = "Replaces the api VM; accepts traffic only from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "API from ALB only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

# RDS — only the ECS task SG may reach :5432
resource "aws_security_group" "rds" {
  name_prefix = "${var.name_prefix}-rds-"
  description = "Replaces the db VM's pg_hba 192.168.56.0/24 rule - but stricter"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from the API tasks only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
}
```

> **Call this out as an improvement.** The current `db_provision.sh` opens PostgreSQL to the entire `192.168.56.0/24` subnet with `md5` auth and `listen_addresses = '*'`. The AWS equivalent accepts `5432` **only** from the ECS task security group, and `publicly_accessible = false` removes the host port-forward entirely. This is a strict, provable security upgrade.

## 2.5 Module: `rds`

```hcl
# infra/modules/rds/main.tf
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.private_subnet_ids      # MUST span >= 2 AZs, even for Single-AZ
}

resource "aws_db_parameter_group" "main" {
  name   = "${var.name_prefix}-pg16"
  family = "postgres16"

  # RDS enforces TLS by default; keep it on and add sslmode=require to the JDBC URL.
  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  # Surface slow queries in CloudWatch Logs. The app does 3 round trips per update;
  # this is how you would notice if that ever became a problem.
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${var.name_prefix}-db"

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.instance_class              # db.t4g.micro

  allocated_storage     = 20
  max_allocated_storage = 100                      # storage autoscaling - avoids a 3am paging event
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name                           # anitracker
  username = var.db_username                       # app_user
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
  port                   = 5432

  publicly_accessible = false                      # <-- the whole point
  multi_az            = var.multi_az                # false in dev, true in prod

  backup_retention_period  = 7
  backup_window            = "16:00-17:00"         # UTC -> 04:00-05:00 NZST
  maintenance_window       = "sun:17:00-sun:18:00"
  copy_tags_to_snapshot    = true
  delete_automated_backups = false

  deletion_protection       = var.deletion_protection   # true in prod; FALSE in dev so destroy works
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name_prefix}-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = { Name = "${var.name_prefix}-db" }
}

output "endpoint" { value = aws_db_instance.main.address }
output "port"     { value = aws_db_instance.main.port }
output "db_name"  { value = aws_db_instance.main.db_name }
```

### RDS design decisions — justify each in the write-up

| Decision | Rationale |
|---|---|
| `db.t4g.micro` (Graviton/ARM) | ~20% cheaper than `db.t3.micro`; the workload is a handful of queries. Burstable credits are ample. |
| Single-AZ in dev, Multi-AZ via `var.multi_az` | Multi-AZ doubles cost for a demo. Exposing it as a flag makes the design defensible without paying for it. |
| `gp3` + `max_allocated_storage` | `gp3` is cheaper than `gp2` with predictable baseline IOPS; autoscaling prevents a disk-full outage. |
| `storage_encrypted = true` | Free, default-on for new instances, and expected by any reviewer. |
| `publicly_accessible = false` | The key security improvement over the Vagrant `listen_addresses = '*'` + host port 5433. |
| `rds.force_ssl = 1` | Forces TLS. **Requires a JDBC URL change** (below). |
| PG 16 rather than the VM's PG 14 | The schema uses nothing newer than PG 9 syntax. PG 16 is the current default major with the longest support runway. |
| `deletion_protection` as a variable | Protects the demo data in prod while still allowing `terraform destroy` in dev. **Forgetting this variable makes dev teardown impossible** — a very common Terraform annoyance. |
| `performance_insights_enabled` | Free tier of 7 days of retention on t4g.micro; makes slow-query debugging possible without a bastion. |

### TLS and the JDBC URL

With `rds.force_ssl = 1`, the JDBC URL must gain `sslmode=require`:

```
jdbc:postgresql://<rds-endpoint>:5432/anitracker?sslmode=require
```

Be precise about what this does and does not do, because a reviewer who knows PostgreSQL will check:

- **`sslmode=require`** encrypts the connection but **does not verify the server's certificate**. It is vulnerable to MITM.
- **`sslmode=verify-full`** verifies the certificate chain and hostname. It requires the **RDS CA bundle** (`global-bundle.pem`) present in the image, with `sslrootcert=/opt/anitracker/certs/global-bundle.pem` added to the URL.

For a coursework deployment `require` is defensible; **`verify-full` is the correct production answer** and is a two-line change (add the PEM to the Dockerfile, extend the URL). State the trade-off explicitly rather than leaving it implicit.

## 2.6 Data migration (`anime-db` → RDS)

The database holds only ~18 seed rows, so the *procedure* is the deliverable, not the data volume.

### The key insight: the schema files are already idempotent

`schema.sql` guards enum creation with a `DO $$ ... IF NOT EXISTS ... $$` block and uses `CREATE TABLE IF NOT EXISTS`. `seed_data.sql` is a single `INSERT ... ON CONFLICT (mal_id) DO UPDATE`. **Both can be re-applied to RDS safely, repeatedly.** That means you never need to dump the *schema* at all — only genuinely user-created rows.

### Option A — `pg_dump` / `psql` (for any real user data)

```bash
# 1. Dump from the running Vagrant DB VM (host port 5433 per the Vagrantfile)
pg_dump \
  --host=localhost --port=5433 \
  --username=app_user --dbname=anitracker \
  --no-owner --no-privileges --no-acl \
  --data-only \
  --file=anitracker-data.sql

# 2. Apply to RDS (via SSM port-forward, or from a temporary SG allowance)
PGPASSWORD='<from Secrets Manager>' psql \
  "host=<rds-endpoint> port=5432 dbname=anitracker user=app_user sslmode=require" \
  -v ON_ERROR_STOP=1 \
  -f anitracker-data.sql
```

**`--no-owner --no-privileges` is not optional.** The VM's `app_user` is a plain login role, but on RDS the master user is **not a superuser** and does not own the `postgres` role. A dump containing `ALTER TABLE ... OWNER TO` or `GRANT` statements will fail with permission errors. Likewise, **`CREATE TYPE watch_status` will fail unless it runs as the RDS master user** — which is exactly why the schema should come from `schema.sql` executed as master, and only *data* should come from the dump.

### Option B — apply the repo's own SQL files (recommended; no dump at all)

1. Terraform creates RDS with `db_name = "anitracker"` and a master user.
2. A bootstrap step (below) runs `schema.sql`, then `seed_data.sql`, then the `GRANT` block copied verbatim from `db_provision.sh`:
   ```sql
   GRANT USAGE ON SCHEMA public TO app_user;
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
   GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO app_user;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public
       GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public
       GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO app_user;
   ```

This makes the migration **fully declarative and re-runnable**, preserving the `vagrant provision db` property exactly.

### Option C — one-off ECS task, triggered by schema changes

The CI/CD-friendly version: a tiny `schema-loader` image (`postgres:16-alpine` + the two SQL files) run as a one-shot Fargate task.

```hcl
resource "aws_ecs_task_definition" "schema_bootstrap" {
  family                   = "${var.name_prefix}-schema-bootstrap"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "schema-loader"
    image     = "${aws_ecr_repository.main.repository_url}:schema-latest"
    essential = false
    environment = [{
      name  = "PGURL"
      value = "host=${aws_db_instance.main.address} port=5432 dbname=${var.db_name} user=${var.db_username} sslmode=require"
    }]
    secrets = [{ name = "PGPASSWORD", valueFrom = "${aws_secretsmanager_secret.db.arn}:password::" }]
    command = ["/bin/sh", "-c",
      "psql \"$PGURL\" -v ON_ERROR_STOP=1 -f /sql/schema.sql && " +
      "psql \"$PGURL\" -v ON_ERROR_STOP=1 -f /sql/seed_data.sql"]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.api.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "schema"
      }
    }
  }])
}

# Re-runs automatically whenever schema.sql changes - the exact analogue of
# "edit schema.sql -> vagrant provision db".
resource "null_resource" "schema_bootstrap" {
  triggers = {
    schema_hash = filesha256("${path.module}/../../schema.sql")
    seed_hash   = filesha256("${path.module}/../../seed_data.sql")
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws ecs run-task \
        --cluster ${aws_ecs_cluster.main.name} \
        --task-definition ${aws_ecs_task_definition.schema_bootstrap.arn} \
        --launch-type FARGATE \
        --network-configuration 'awsvpcConfiguration={subnets=[${join(",", var.public_subnet_ids)}],securityGroups=[${aws_security_group.ecs.id}],assignPublicIp=ENABLED}' \
        --region ${var.region}
    EOT
  }

  depends_on = [aws_db_instance.main, aws_ecs_cluster.main]
}
```

**The `triggers` map is the important part.** Without it the bootstrap runs once and never again; with it, editing `schema.sql` in the repo and running `terraform apply` re-applies it — reproducing the developer workflow from README §8 ("Schema/seed change → reprovision DB VM") as a single declarative step.

### Option D — SSM Session Manager port-forward (no bastion, no public RDS)

```bash
# Requires enable_execute_command = true on the ECS service (set below)
aws ssm start-session \
  --target ecs:anitracker-cluster_anitracker-api_<task-id>_<runtime-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<rds-endpoint>"],"portNumber":["5432"],"localPortNumber":["5432"]}'
```

Then `psql -h localhost -p 5432` locally. **Cleanest option for a demo**: no bastion EC2 instance to pay for, no `publicly_accessible = true` anywhere, and every session is logged in CloudTrail. Use this for Phase-4 verification.

### Explicit anti-pattern: do not use AWS DMS

The dataset is 18 rows. DMS requires a replication instance running hourly for zero benefit, plus a schema-conversion assessment that would flag the `watch_status` enum. **Say so in the write-up.** Recognising when *not* to adopt a service is part of a credible migration plan.

## 2.7 Module: `ecr` + the container image

```hcl
# infra/modules/ecr/main.tf
resource "aws_ecr_repository" "api" {
  name                 = "${var.name_prefix}-api"
  image_tag_mutability = "IMMUTABLE"        # never overwrite a released tag
  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Retain the last 10 images"
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 }
      action       = { type = "expire" }
    }]
  })
}
```

### `docker/backend.Dockerfile`

**Read the `sourceSets` note before writing this.** `build.gradle` declares `srcDirs = ['backend/src/main']` *relative to the Gradle project root*. So inside the build stage, `build.gradle`, `settings.gradle`, `gradlew`, `gradle/`, and `backend/` must preserve their exact relative positions. If you flatten the layout, `./gradlew installDist` produces an empty distribution and the container fails at start with `ClassNotFoundException: app.AnimeTrackerApp`.

```dockerfile
# syntax=docker/dockerfile:1.7

# ---------- Stage 1: build ----------
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /src

# Copy the wrapper and build scripts FIRST so the ~130 MB Gradle distribution
# download is cached and not repeated on every source change.
COPY gradlew gradlew.bat ./
COPY gradle/ gradle/
COPY settings.gradle build.gradle ./
RUN chmod +x gradlew && ./gradlew --version --no-daemon

# Now the source.  backend/ MUST stay at this relative path: build.gradle hardcodes
# sourceSets { main { java { srcDirs = ['backend/src/main'] } } }
COPY backend/ backend/
RUN ./gradlew clean installDist --no-daemon

# ---------- Stage 2: runtime ----------
FROM eclipse-temurin:17-jre-jammy

RUN useradd --system --uid 10001 --create-home appuser

WORKDIR /opt/anitracker
# installDist output is self-contained: bin/ launcher scripts + lib/*.jar
COPY --from=build --chown=appuser:appuser /src/build/install/anitracker ./

# Uncomment for sslmode=verify-full
# COPY --chown=appuser:appuser docker/certs/global-bundle.pem /opt/anitracker/certs/global-bundle.pem

USER appuser
EXPOSE 8080

# Mirrors the VM provisioning gate's `curl /health`
HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/opt/anitracker/bin/anitracker"]
```

**Five things this Dockerfile must get right:**

1. **`EXPOSE 8080` and bind on `0.0.0.0`.** Jooby/Netty binds all interfaces on port 8080 by default. If you override `server.host` to `127.0.0.1`, **every ALB and ECS health check fails** with a connection-refused and the service never reaches steady state. This is the single most common containerisation bug for this app.
2. **JVM memory must respect the container limit.** A 512 MB Fargate task with a JVM defaulting to 25% of *host* memory is a recipe for an OOM kill. `-XX:+UseContainerSupport` (on by default in Java 17) reads the cgroup limit, but set `JAVA_TOOL_OPTIONS=-XX:MaxRAMPercentage=75` explicitly in the task definition so the behaviour is visible and intentional.
3. **Run as non-root.** The JRE image defaults to root; `appuser` uid 10001 is the minimum hardening.
4. **`.dockerignore` is mandatory, not optional.** Without it the build context includes `graphify-out/` (a committed code graph with a full AST cache — dozens of files), `node_modules/`, `frontend/`, `build/`, `bin/`, `.git/`, `.vagrant/`, and `infra/`. That is tens of megabytes of noise sent to the daemon on every build.
5. **Multi-arch matters.** If the task definition sets `cpu_architecture = "ARM64"` (recommended for cost), the image **must** be built with `--platform linux/arm64`. A mismatch yields an immediate `CannotPullContainerError` or an exec-format error. Pin both sides.

```
# .dockerignore  (create at repo root)
.git
.gitignore
.gitattributes
graphify-out/
frontend/
node_modules/
**/node_modules/
build/
bin/
.vagrant/
.vscode/
.idea
infra/
*.md
README.md
seed_data.sql.bak
```

### `docker/schema-loader.Dockerfile` (only for Option C)

```dockerfile
FROM postgres:16-alpine
RUN mkdir -p /sql
COPY schema.sql /sql/schema.sql
COPY seed_data.sql /sql/seed_data.sql
USER postgres
CMD ["true"]        # overridden by the task definition's `command`
```

### The frontend needs no image

The Vite build (`cd frontend && npm ci && npm run build` → `frontend/dist/`) is uploaded directly to S3. That is the exact analogue of `web_provision.sh`'s `cp -r dist/. /var/www/anitracker/`.
`
