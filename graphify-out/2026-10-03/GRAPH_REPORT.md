# Graph Report - Anitracker  (2026-10-02)

## Corpus Check
- 58 files · ~10,533 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 11 file(s) not represented in the graph (top: (none) 4, .ico 1, .css 1)

## Summary
- 256 nodes · 306 edges · 23 communities (11 shown, 12 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d0cb46c1`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Anime
- Main.vue
- DetailPage.vue
- frontend/package.json
- Anitracker (Three-VM Internet Movie/Anime Database)
- WatchStatus
- App.vue
- SearchBarGeneric.vue
- jsconfig.json
- mala-imdb
- package.json
- api_provision.sh
- db_provision.sh
- web_provision.sh
- deploy.sh script
- destroy.sh script

## God Nodes (most connected - your core abstractions)
1. `Anime` - 31 edges
2. `Anitracker (Three-VM Internet Movie/Anime Database)` - 16 edges
3. `WatchStatus` - 11 edges
4. `vue` - 10 edges
5. `AnimeJdbiDAO` - 9 edges
6. `AnimeTrackerApp` - 8 edges
7. `AWS deployment (Terraform)` - 8 edges
8. `AnimeDAO` - 7 edges
9. `mala-imdb` - 5 edges
10. `scripts` - 4 edges

## Surprising Connections (you probably didn't know these)
- `Anime` --references--> `WatchStatus`  [EXTRACTED]
  backend/src/main/app/Anime.java → backend/src/main/app/WatchStatus.java
- `AnimeJdbiDAO` --references--> `Anime`  [EXTRACTED]
  backend/src/main/app/AnimeJdbiDAO.java → backend/src/main/app/Anime.java

## Import Cycles
- None detected.

## Communities (23 total, 12 thin omitted)

### Community 0 - "Anime"
Cohesion: 0.07
Nodes (4): Anime, AnimeDAO, AnimeJdbiDAO, AnimeTrackerApp

### Community 1 - "Main.vue"
Cohesion: 0.06
Nodes (26): props, props, isModalOpen, dataArray, props, selectedAnime, addAnime(), animeList (+18 more)

### Community 2 - "DetailPage.vue"
Cohesion: 0.06
Nodes (24): props, animeData, watchStatusLabels, props, progressPercentage, props, isCompleted, isDropped (+16 more)

### Community 3 - "frontend/package.json"
Cohesion: 0.09
Nodes (21): dependencies, vue, vue-router, devDependencies, vite, vite-plugin-vue-devtools, @vitejs/plugin-vue, engines (+13 more)

### Community 4 - "Anitracker (Three-VM Internet Movie/Anime Database)"
Cohesion: 0.06
Nodes (35): 10) Troubleshooting, 11) Assessment evidence pointers, 12) API behavior notes, 13) AI/reuse attribution note, 1) Architecture (3 VM requirement), 2) Tools and purpose, 3) Supported host environment, 4) One-command deployment (+27 more)

### Community 5 - "WatchStatus"
Cohesion: 0.14
Nodes (6): WatchStatus, COMPLETED, DROPPED, ON_HOLD, PLAN_TO_WATCH, WATCHING

### Community 6 - "App.vue"
Cohesion: 0.23
Nodes (4): apiLinks, apiQueries, watchStatusLabels, router

### Community 7 - "SearchBarGeneric.vue"
Cohesion: 0.50
Nodes (4): emit, handleSearch(), isSearchDisabled, searchQuery

### Community 8 - "jsconfig.json"
Cohesion: 0.50
Nodes (3): compilerOptions, paths, exclude

### Community 9 - "mala-imdb"
Cohesion: 0.25
Nodes (7): Compile and Hot-Reload for Development, Compile and Minify for Production, Customize configuration, mala-imdb, Project Setup, Recommended Browser Setup, Recommended IDE Setup

### Community 10 - "package.json"
Cohesion: 0.50
Nodes (3): dependencies, vue-router, vue-router

## Knowledge Gaps
- **111 isolated node(s):** `WATCHING`, `COMPLETED`, `ON_HOLD`, `DROPPED`, `PLAN_TO_WATCH` (+106 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 155 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `vue` connect `DetailPage.vue` to `Main.vue`, `frontend/package.json`, `App.vue`, `SearchBarGeneric.vue`?**
  _High betweenness centrality (0.099) - this node is a cross-community bridge._
- **Why does `Anime` connect `Anime` to `WatchStatus`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **Why does `WatchStatus` connect `WatchStatus` to `Anime`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **What connects `WATCHING`, `COMPLETED`, `ON_HOLD` to the rest of the system?**
  _111 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Anime` be split into smaller, more focused modules?**
  _Cohesion score 0.06636500754147813 - nodes in this community are weakly interconnected._
- **Should `Main.vue` be split into smaller, more focused modules?**
  _Cohesion score 0.06190476190476191 - nodes in this community are weakly interconnected._
- **Should `DetailPage.vue` be split into smaller, more focused modules?**
  _Cohesion score 0.06417112299465241 - nodes in this community are weakly interconnected._