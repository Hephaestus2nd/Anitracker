# Graph Report - Internet_Movie_Database  (2026-10-03)

## Corpus Check
- 56 files · ~10,607 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 11 file(s) not represented in the graph (top: (none) 3, .tftpl 2, .ico 1)

## Summary
- 299 nodes · 423 edges · 24 communities (11 shown, 13 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `4492b481`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Anime
- Main.vue
- DetailPage.vue
- frontend/package.json
- Local Deployment (Vagrant)
- WatchStatus
- var.project_name
- SearchBarGeneric.vue
- jsconfig.json
- AWS deployment (Terraform)
- package.json
- api_provision.sh
- db_provision.sh
- web_provision.sh
- deploy.sh script
- destroy.sh script
- .terraform.lock.hcl

## God Nodes (most connected - your core abstractions)
1. `Anime` - 31 edges
2. `var.project_name` - 17 edges
3. `aws_instance.api` - 16 edges
4. `AWS deployment (Terraform)` - 14 edges
5. `WatchStatus` - 11 edges
6. `aws_instance.web` - 11 edges
7. `aws_vpc.main` - 11 edges
8. `aws_db_instance.main` - 11 edges
9. `vue` - 10 edges
10. `Local Deployment (Vagrant)` - 10 edges

## Surprising Connections (you probably didn't know these)
- `Anime` --references--> `WatchStatus`  [EXTRACTED]
  backend/src/main/app/Anime.java → backend/src/main/app/WatchStatus.java
- `output.alb_dns_name` --references--> `aws_lb.main`  [EXTRACTED]
  infra/outputs.tf → infra/alb.tf
- `output.site_url` --references--> `aws_lb.main`  [EXTRACTED]
  infra/outputs.tf → infra/alb.tf
- `aws_instance.api` --references--> `local.db_app_user`  [EXTRACTED]
  infra/ec2_api.tf → infra/rds.tf
- `output.rds_endpoint` --references--> `aws_db_instance.main`  [EXTRACTED]
  infra/outputs.tf → infra/rds.tf

## Import Cycles
- None detected.

## Communities (24 total, 13 thin omitted)

### Community 0 - "Anime"
Cohesion: 0.07
Nodes (4): Anime, AnimeDAO, AnimeJdbiDAO, AnimeTrackerApp

### Community 1 - "Main.vue"
Cohesion: 0.06
Nodes (28): props, props, props, props, isModalOpen, dataArray, props, selectedAnime (+20 more)

### Community 2 - "DetailPage.vue"
Cohesion: 0.06
Nodes (26): apiLinks, apiQueries, watchStatusLabels, router, animeData, watchStatusLabels, progressPercentage, props (+18 more)

### Community 3 - "frontend/package.json"
Cohesion: 0.09
Nodes (21): dependencies, vue, vue-router, devDependencies, vite, vite-plugin-vue-devtools, @vitejs/plugin-vue, engines (+13 more)

### Community 4 - "Local Deployment (Vagrant)"
Cohesion: 0.10
Nodes (20): AI/reuse attribution note, Anitracker (Three-VM Internet Movie/Anime Database), API behavior notes, Backend change (Java/API or DB access logic), Common problems, Demonstration data, Deploy, Destroy (+12 more)

### Community 5 - "WatchStatus"
Cohesion: 0.17
Nodes (6): WatchStatus, COMPLETED, DROPPED, ON_HOLD, PLAN_TO_WATCH, WATCHING

### Community 6 - "var.project_name"
Cohesion: 0.10
Nodes (40): aws_db_instance.main, aws_db_subnet_group.main, aws_instance.api, aws_instance.web, aws_internet_gateway.main, aws_lb_listener.http, aws_lb.main, aws_lb_target_group_attachment.web (+32 more)

### Community 7 - "SearchBarGeneric.vue"
Cohesion: 0.50
Nodes (4): emit, handleSearch(), isSearchDisabled, searchQuery

### Community 8 - "jsconfig.json"
Cohesion: 0.50
Nodes (3): compilerOptions, paths, exclude

### Community 9 - "AWS deployment (Terraform)"
Cohesion: 0.13
Nodes (14): Architecture, AWS credentials (Learner Lab), AWS deployment (Terraform), Common problems, Configuration, Debugging a deployment, Deploy, Destroy (+6 more)

### Community 10 - "package.json"
Cohesion: 0.50
Nodes (3): dependencies, vue-router, vue-router

## Knowledge Gaps
- **108 isolated node(s):** `WATCHING`, `COMPLETED`, `ON_HOLD`, `DROPPED`, `PLAN_TO_WATCH` (+103 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 150 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `vue` connect `DetailPage.vue` to `Main.vue`, `frontend/package.json`, `SearchBarGeneric.vue`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._
- **Why does `AnimeTrackerApp` connect `Anime` to `AWS deployment (Terraform)`?**
  _High betweenness centrality (0.062) - this node is a cross-community bridge._
- **Why does `Anime` connect `Anime` to `WatchStatus`?**
  _High betweenness centrality (0.059) - this node is a cross-community bridge._
- **What connects `WATCHING`, `COMPLETED`, `ON_HOLD` to the rest of the system?**
  _108 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Anime` be split into smaller, more focused modules?**
  _Cohesion score 0.06531204644412192 - nodes in this community are weakly interconnected._
- **Should `Main.vue` be split into smaller, more focused modules?**
  _Cohesion score 0.05512820512820513 - nodes in this community are weakly interconnected._
- **Should `DetailPage.vue` be split into smaller, more focused modules?**
  _Cohesion score 0.059800664451827246 - nodes in this community are weakly interconnected._