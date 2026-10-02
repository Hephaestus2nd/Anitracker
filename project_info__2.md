# Anitracker — Codebase Overview & AWS Migration Plan

*Full report saved to `project_info__1.md` (Part 1 = codebase documentation, complete; Part 2 = migration plan through §2.7 on disk — the remainder is below).*

---

## PART 1 — What this codebase is

### Summary

**Anitracker** is a three-tier anime watchlist app built for COSC349 Assignment 1. It is **deliberately infrastructure-heavy and application-simple**: the submission is really about the *reproducible three-VM deployment*, not the feature set. The app is ~400 lines of Java and ~1,200 lines of Vue/JS. **No tests. No authentication. No connection pooling.**

Stack: **Java 17 + Jooby 3 (Netty) + JDBI3 → PostgreSQL** backend, **Vue 3 + Vite 8** frontend, **Nginx** static host + `/api` proxy, **Vagrant + VirtualBox** orchestration.

### The three-VM topology (`Vagrantfile`)

| VM | IP | Role |
|---|---|---|
| `anime-db` | 192.168.56.10 | PostgreSQL 14, `anitracker` DB, `app_user`/`AppPass123` |
| `anime-api` | 192.168.56.11 | Jooby/Netty on `:8080`, systemd unit, health-gated start |
| `anime-web` | 192.168.56.12 | Nginx `:80`, serves Vue `dist/`, proxies `/api/` → api VM |

Host ports: web `8080→80`, api `8081→8080`, db `5433→5432`.

### The single most important gotcha: **the backend has no `/api` prefix**

The prefix is stripped *twice*, and it's invisible unless you read the provisioning scripts:

- **Nginx:** `location /api/ { proxy_pass http://192.168.56.11:8080/; }` — the **trailing slash** on `proxy_pass` is what strips `/api`.
- **Vite dev:** `rewrite: (path) => path.replace(/^\/api/, '')`.

So the real contract is `GET /anime`, `GET /health`. But `frontend/src/helpers/apiStuff.js` sets `API_ANIME = "/api/anime"`. **Any AWS design routing `/api/*` to the backend must reproduce this rewrite** or the entire UI breaks. This is the #1 cause of a broken migration here.

### API surface (`AnimeTrackerApp.java` — the whole backend in one file)

| Method | Path | Behaviour |
|---|---|---|
| GET | `/health` | `SELECT 1` → 200 `{status,database,service}`; **503** on any `RuntimeException` |
| GET | `/anime` | Full table, `ORDER BY mal_id`, **no pagination** |
| GET | `/anime/{id}` | 200 or **404** `{"error":"Anime not found"}` |
| POST | `/anime` | validate → normalise → insert → re-read → **200 (not 201)** |
| PUT | `/anime/{id}` | 400/404 branches; body/URL `malId` must agree; **3 DB round trips** |
| DELETE | `/anime/{id}` | **204** or 404 |

### Key non-obvious findings

1. **No connection pooling.** `Jdbi.create(url, user, pass)` builds a `DriverManager` factory → **a brand-new PostgreSQL connection per DAO call**, including every `/health` probe. Fine on a LAN; fatal on RDS. **Highest-value fix in the whole plan.**

2. **The status vocabulary is triplicated** across `schema.sql` (`CREATE TYPE watch_status AS ENUM`), `WatchStatus.java`, and `watchStatusLabels.js` — `'On-Hold'` has a hyphen, `'Plan to Watch'` has spaces. Nothing keeps them in sync.

3. **`watch_status` is a real PostgreSQL enum**, not a VARCHAR. `CREATE TYPE` needs the `DO $$ ... IF NOT EXISTS` guard, and on RDS it must run as the **master user**. `AnimeJdbiDAO` uses `CAST(:watchStatus AS watch_status)`.

4. **`Anime.getWatchStatus()` returns a String**, not the enum — so the wire format is `"Plan to Watch"`, and `Anime.setWatchStatus` **silently swallows** an invalid value into `null`, which `validateAnime` then reports. Two-stage error funnel.

5. **`@RegisterBeanMapper` relies on pure snake_case↔camelCase convention** — no explicit column mapping. `background_image_url`→`backgroundImageUrl` works by luck of naming.

6. **The server never calls AniList.** The browser does, directly. `seed_data.sql` carries the rationale comment (Jikan rate limits/504s). **Consequence: the backend has ZERO third-party runtime dependencies** — no NAT gateway, no VPC endpoints needed. This is the most migration-friendly fact in the repo.

7. **`sourceSets { srcDirs = ['backend/src/main'] }`** — not `src/main/java`. This hardcodes the relative layout that the Docker build context must preserve or `installDist` produces nothing.

8. **The stub `AnimeDAO.java` is dead** — zero implementations, zero call sites. `AnimeTrackerApp` uses `AnimeJdbiDAO` directly.

9. **Root `package.json` is broken** — declares `vue-router@^5.3.0`, which **does not exist**. Any root-level `npm ci` fails. Delete it.

10. **No error handler installed.** Deliberate errors return `{"error": ...}`, but unexpected ones return Jooby's default 500 body — **which the frontend never parses**. The careful error messages are effectively invisible; users see `Error 500: Internal Server Error`.

11. **`graphify-out/` is committed and NOT gitignored** — a code graph plus a full AST cache. It would bloat the Docker build context.

12. **`AppPass123` is hardcoded in ≥5 files** and is in git history. Rotation is mandatory; `git rm` alone won't help.

### The five things that make this migration LOW risk

| Property | Why it matters |
|---|---|
| **Stateless** — PostgreSQL is the only shared state | `desired_count = 2` works with zero code change; no sticky sessions |
| **No server-side third-party calls** | No NAT gateway, no VPC endpoints, no egress cost |
| **Environment-variable DB contract already exists** (`DB_URL`/`DB_USER`/`DB_PASSWORD`) | No refactor needed — only the hardcoded *defaults* must go |
| **Schema files are already idempotent** (`DO $$` guard + `ON CONFLICT DO UPDATE`) | The seed can be re-applied to RDS repeatedly |
| **Single backend file + single frontend API constant** | The whole surface is comprehensible |

---

## PART 2 — AWS migration plan (Terraform + RDS)

### 2.1 Thesis

| Current | AWS | Risk |
|---|---|---|
| `anime-db` | **RDS for PostgreSQL 16** (`db.t4g.micro`, private subnets) | Low |
| `anime-api` | **ECS Fargate** behind an **ALB** (or App Runner) | Low |
| `anime-web` | **S3 + CloudFront** (recommended) | Medium — the `/api` strip + SPA fallback |
| Vagrant | **Terraform** | This is the deliverable |

**Mandatory code changes: 2.** **Recommended: 2.** Everything else is infrastructure.

### 2.2 Target architecture

```
Internet → Route 53 → CloudFront (ACM cert in us-east-1)
                          ├── default /*      → S3 (private, via OAC)   ← Vue dist
                          └── /api/*          → CloudFront Function (strip /api)
                                                  → ALB (:443) → ECS Fargate (:8080)
                                                                      → RDS PostgreSQL (private)
```

**Why CloudFront+S3 instead of a second Fargate service:** it replaces the Nginx static-serving job for free (plus compression and edge caching Nginx never had), and the behavior replaces the proxy. No second service, no extra hop.

**VPC:** `10.0.0.0/16`, 2 public subnets (`10.0.0.0/24`, `10.0.1.0/24`), **2 private subnets** (`10.0.10.0/24`, `10.0.11.0/24`) — RDS requires ≥2 AZs even Single-AZ.

**Fargate networking:** run tasks in **public subnets with a public IP** — saves the **$32/mo NAT gateway**, and the SG still blocks everything except ALB→8080. If the rubric demands private networking, use **VPC endpoints** (ECR, S3, Logs, Secrets Manager) rather than a NAT gateway.

**Three security groups, one per former VM** — and note the **security improvement**: `db_provision.sh` opens Postgres to all of `192.168.56.0/24` with `listen_addresses='*'`; the AWS equivalent allows **5432 only from the ECS task SG**, with `publicly_accessible = false`.

### 2.3 RDS design

- `db.t4g.micro` (Graviton, ~20% cheaper than `t3`), **PG 16**, `gp3` 20 GB with `max_allocated_storage = 100`
- `publicly_accessible = false`, `storage_encrypted = true`, `deletion_protection` driven by a **variable** (or dev teardown breaks)
- `multi_az` as a variable (false in dev)
- 7-day backups, `performance_insights_enabled`, `enabled_cloudwatch_logs_exports = ["postgresql"]`
- Parameter group: **`rds.force_ssl = 1`** → the JDBC URL must gain **`?sslmode=require`**

> Be explicit about TLS: `sslmode=require` **encrypts but does not verify** the certificate. `verify-full` needs the RDS CA bundle (`global-bundle.pem`) in the image + `sslrootcert=`. State the trade-off rather than leaving it implicit.

### 2.4 Data migration

**Key insight: you don't need a dump.** `schema.sql` guards enum creation and uses `CREATE TABLE IF NOT EXISTS`; `seed_data.sql` is `ON CONFLICT (mal_id) DO UPDATE`. Both are safely re-runnable.

1. RDS created with `db_name = anitracker` + master user.
2. Apply **`schema.sql` as the master user** (creates the `watch_status` enum — `app_user` can't).
3. Apply `seed_data.sql` (idempotent).
4. Apply the `GRANT` block **verbatim from `db_provision.sh`** (`GRANT USAGE ON SCHEMA public...` + `ALTER DEFAULT PRIVILEGES`).

**If you must dump real data:** `pg_dump --no-owner --no-privileges --data-only`. Ownership statements fail because the RDS master is not a superuser.

**Two delivery mechanisms for the bootstrap:**
- **`null_resource` with `triggers = { schema_hash = filesha256("...") }`** running a one-shot `aws ecs run-task` of a `schema-loader` image → **editing `schema.sql` + `terraform apply` reproduces `vagrant provision db` exactly.**
- **SSM Session Manager port-forward** via ECS Exec → no bastion, no public RDS. Use this for Phase-4 verification.

**Explicit anti-pattern: do NOT use AWS DMS.** 18 rows, and its schema assessment would flag the enum. Say so — knowing when *not* to use a service is part of a credible plan.

### 2.5 Containerisation — `docker/backend.Dockerfile`

**The `sourceSets` remap dictates the layout.** `build.gradle` hardcodes `srcDirs = ['backend/src/main']`, so in the build stage `build.gradle`, `settings.gradle`, `gradlew`, `gradle/`, and `backend/` must sit at their **exact relative positions** — flatten them and you get `ClassNotFoundException: app.AnimeTrackerApp`.

```dockerfile
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /src
COPY gradlew gradlew.bat ./          # wrapper first → caches the ~130MB Gradle download
COPY gradle/ gradle/
COPY settings.gradle build.gradle ./
RUN chmod +x gradlew && ./gradlew --version --no-daemon
COPY backend/ backend/               # MUST stay at this path
RUN ./gradlew clean installDist --no-daemon

FROM eclipse-temurin:17-jre-jammy
RUN useradd --system --uid 10001 --create-home appuser
WORKDIR /opt/anitracker
COPY --from=build --chown=appuser:appuser /src/build/install/anitracker ./
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/health || exit 1
ENTRYPOINT ["/opt/anitracker/bin/anitracker"]
```

**Five must-get-rights:** (1) bind `0.0.0.0:8080`, not `127.0.0.1` — or *every* health check fails; (2) `JAVA_TOOL_OPTIONS=-XX:MaxRAMPercentage=75` in the task def, or the JVM ignores the 512 MB cgroup limit and gets OOM-killed (exit 137); (3) non-root user; (4) **`.dockerignore` is mandatory** — otherwise `graphify-out/` (AST cache), `frontend/`, `node_modules/`, `infra/` all go to the daemon; (5) if `cpu_architecture = "ARM64"` you **must** build `--platform linux/arm64` — a mismatch is an immediate `CannotPullContainerError`.

### 2.6 ECS task definition — the critical bits

```hcl
cpu = "256", memory = "512", network_mode = "awsvpc"   # forces target_type = "ip"
runtime_platform { operating_system_family = "LINUX", cpu_architecture = "ARM64" }

environment = [
  { name = "DB_URL", value = "jdbc:postgresql://${...address}:5432/anitracker?sslmode=require" },
  { name = "JAVA_TOOL_OPTIONS", value = "-XX:MaxRAMPercentage=75 -XX:+UseContainerSupport" }
]
secrets = [
  { name = "DB_USER",     valueFrom = "${...secret.arn}:username::" },
  { name = "DB_PASSWORD", valueFrom = "${...secret.arn}:password::" }
]
```

**`secrets` not `environment` costs nothing and keeps the password out of `terraform plan`, the ECS console, and `describe-task-definition`.** The app reads `System.getenv()` either way — **zero code change required**.

**IAM: the task role must be EMPTY.** The backend's only outbound dependency is PostgreSQL — no AWS SDK on the classpath. Least privilege is trivially satisfied, and that's a *direct consequence* of the browser-direct AniList design.

**Service:** `desired_count = 2` (safe because stateless), `deployment_minimum_healthy_percent = 100`, `health_check_grace_period_seconds = 60` (JVM boot), `enable_execute_command = true` (for the SSM port-forward), and **`lifecycle { ignore_changes = [task_definition] }`** so CI can register revisions without Terraform fighting it.

### 2.7 The Nginx replacement — CloudFront must reproduce TWO things

| Nginx | AWS equivalent |
|---|---|
| `try_files $uri $uri/ /index.html;` | **custom_error_response for 403 AND 404 → `/index.html`, response_code 200** |
| `location /api/ { proxy_pass .../; }` | **CloudFront Function** rewriting `^/api` → `` |

**The prefix strip:**

```js
function handler(event) {
  var request = event.request;
  request.uri = request.uri.replace(/^\/api/, '');
  if (request.uri === '') { request.uri = '/'; }
  return request;
}
```

**Why not the alternatives:** ALB listener rules **cannot rewrite paths** (so routing `/api/*` to the API target group delivers `/api/anime`, which 404s — the most common wrong answer); changing `apiStuff.js` to `/anime` diverges dev from prod and collides with the SPA route `/anime/:id`; adding a Jooby route prefix is a code change for an infrastructure concern.

**Four CloudFront details that will bite you:**
1. **The ACM certificate MUST be in `us-east-1`**, whatever region everything else uses — hence a `provider "aws" { alias = "us_east_1" }`.
2. **`/api/*` must use the `CachingDisabled` managed policy** — otherwise `GET /anime` is cached and edits "don't save".
3. **`AllViewerExceptHostHeader`** origin-request policy (needed the moment auth is added; the Host must be rewritten to the ALB DNS).
4. **Map BOTH 403 and 404.** With OAC the bucket is private, so S3 returns **403** for a missing key. Mapping only 404 leaves `/anime/52991` broken on refresh — with an intermittent-looking symptom.

**CORS is not needed** because everything is one origin. That's the strongest argument for this design — and it's only possible because `/api` is an infrastructure concern, not an app concern.

### 2.8 Required code changes

**(1) HikariCP — MANDATORY.** `build.gradle`: `+ com.zaxxer:HikariCP:5.1.0`. Then:

```java
HikariConfig c = new HikariConfig();
c.setJdbcUrl(dbUrl); c.setUsername(dbUser); c.setPassword(dbPassword);
c.setMaximumPoolSize(8);          // t4g.micro allows ~85; RDS reserves several
c.setConnectionTimeout(5_000);    // fail fast instead of hanging 30 s
c.setMaxLifetime(1_200_000);      // MUST be < the server-side idle timeout, or the pool
                                  // hands out connections the server already closed
Jdbi jdbi = Jdbi.create(new HikariDataSource(c));
```

**Why it's not optional:** today every `/anime` request *and every ALB health probe* spawns a fresh PostgreSQL backend process. With two tasks health-checked every 30 s, `DatabaseConnections` climbs immediately and `db.t4g.micro` starts returning `FATAL: sorry, too many clients already`. **It is the expected first failure, not a theoretical risk.**

**(2) Remove the hardcoded fallbacks — MANDATORY.**

```java
private static String required(String k) {
  String v = System.getenv(k);
  if (v == null || v.isBlank()) throw new IllegalStateException("Required env var " + k + " is not set");
  return v;
}
String dbUrl = required("DB_URL"); // ...and USER / PASSWORD
```

Otherwise a misconfigured task **starts successfully** and then hangs every request trying to reach `192.168.56.10`, an address that doesn't exist in the VPC. **Failing at boot beats failing at request time.**

**(3) Jooby `error(StatusCode.SERVER_ERROR, ...)`** returning the same `{"error": ...}` shape, and logging the trace to CloudWatch.

**(4) `GET /live` (shallow, no DB) alongside `/health` (deep).** Point the **ALB** at `/live`. Reason: `/health` runs `SELECT 1`, so **an RDS blip drains the entire service** — including during a maintenance window. With `/live`, an unhealthy task stays registered and can recover, while a CloudWatch alarm fires on `/health`. **This is the correct production answer and a genuinely good talking point.**

**(5) Housekeeping:** remove `usePolling: true` from `vite.config.js` (VirtualBox-only workaround); delete `AnimeDAO.java`; delete the root `package.json`/`package-lock.json`.

### 2.9 Migration phases (each independently verifiable)

| # | Phase | Gate |
|---|---|---|
| 0 | Hygiene: delete broken root `package.json`, `.gitignore` + `.dockerignore`, secret scan, rotate `AppPass123` | No plaintext creds tracked |
| 1 | Code: HikariCP, required-env, error handler, `/live` | `./gradlew clean installDist` + endpoints unchanged vs. the Vagrant DB |
| **2** | **Containerise; run against the still-running Vagrant DB** | **GO/NO-GO GATE** — `curl localhost:8080/anime` returns all 18 rows |
| 3 | `terraform apply` network + secrets + rds | Connect via SSM port-forward; empty schema |
| 4 | Bootstrap: `schema.sql` (as master) → `seed_data.sql` → `GRANT` block | Same 5 rows as the Vagrant DB (README §5 check 2) |
| 5 | ecr + ecs + alb | `curl <alb>/health` → `{"status":"ok","database":"connected"}` |
| 6 | static-site + frontend deploy | Catalogue loads; `/api/anime` reaches the ALB; **refresh on `/anime/52991` still works** |
| 7 | ACM (us-east-1) + Route 53 alias → **CloudFront** | https 200, http 301, cert *Issued* |
| 8 | GitHub Actions (OIDC, no long-lived keys) | Push → new revision → steady state, no Terraform involvement |
| 9 | Alarms: `rds_cpu`, **`rds_connections`**, `alb_5xx`, `rds_free_storage`, `ecs_running_tasks` | Kill a task → alarm fires → ECS replaces it |
| 10 | Parallel run ≥7 days, diff responses, then `terraform destroy` + `vagrant destroy -f` | Bodies match; zero traffic in the Nginx access log |

> The **`rds_connections` alarm is directly motivated by the missing-pool defect** — it's the metric that would have caught it in production.

### 2.10 CI/CD — the direct analogue of README §8

```yaml
# backend.yml  (paths: backend/**, build.gradle, settings.gradle, gradle/**)
docker buildx build --platform linux/arm64 -f docker/backend.Dockerfile -t $ECR:$SHA --push .
aws ecs update-service --cluster anitracker-cluster --service anitracker-api --force-new-deployment
aws ecs wait services-stable --cluster anitracker-cluster --services anitracker-api
```

```yaml
# frontend.yml  (paths: frontend/**)
- working-directory: frontend      # MANDATORY — the root package.json is broken
  run: npm ci && npm run build
- run: aws s3 sync frontend/dist/ s3://$BUCKET/ --delete
- run: aws cloudfront create-invalidation --distribution-id $CF_ID --paths '/*'
```

- **`paths:` filters = "reprovision only the impacted VM"**
- **`--platform linux/arm64` must match `cpu_architecture`** — pin both sides
- **OIDC (`id-token: write`)** so there are no long-lived AWS keys in GitHub secrets
- `working-directory: frontend` is required or the broken root manifest breaks `npm ci`

### 2.11 Cost (ap-southeast-2, on-demand, USD/month)

RDS `db.t4g.micro` + storage ~$15 · Fargate 2×0.25vCPU/512MB ~$18 · ALB ~$17 · CloudFront ~$1 · S3/ECR/Secrets ~$0.55 · CloudWatch ~$4 · Route 53 ~$0.60 · **ACM free** → **≈ $56/month**.

Cheaper variant: `desired_count = 1` (−$9), and **App Runner instead of the ALB** (−$17) → **~$19/month**. App Runner gives managed TLS and scale-to-zero, but **no path-based routing** (CloudFront handles `/api/*`), needs a **VPC connector** for private RDS, and offers far less tuning surface.

**Recommend ECS + ALB for the submission** (demonstrates the network design and health-check tuning) and document App Runner as the optimisation. Also note the honest value proposition: **the migration isn't about cost — it's that the app becomes permanently available at a URL with no host dependency.**

### 2.12 Top risks, ranked

1. **No connection pool** → `too many clients already` after minutes of health checks
2. **`/api` not stripped** → every API call 404s, empty catalogue
3. **Only 404 mapped to `index.html`, not 403** → home works, deep-link refresh breaks
4. **Hardcoded DB fallbacks** → task reports RUNNING and hangs every request
5. **`sourceSets` layout broken in Docker** → empty `lib/`, `ClassNotFoundException`
6. **Wrong CPU architecture** → immediate `CannotPullContainerError`
7. **`CREATE TYPE watch_status` run as `app_user`** → bootstrap aborts
8. **`pg_dump` with ownership statements** → `must be owner of table`
9. **Missing `sslmode=require`** with `rds.force_ssl=1` → `no pg_hba.conf entry`
10. **CloudFront caching `/api/*`** → edits appear not to save
11. **ACM cert in the wrong region** → stuck *Pending validation*
12. **Fargate OOM (exit 137)** → set `MaxRAMPercentage`
13. **ALB health check on `/health`** → RDS blip drains the service
14. **`deletion_protection = true` in dev** → `terraform destroy` fails
15. **Root `package.json`** → `npm ci` fails on `vue-router@5.3.0`

### 2.13 Summary — what changes

**Unchanged:** all of `Anime.java` / `AnimeJdbiDAO.java` / `WatchStatus.java`, `schema.sql`, `seed_data.sql` verbatim, all six endpoints and status codes, every Vue component, the `/api/anime` contract, and the `DB_URL`/`DB_USER`/`DB_PASSWORD` env contract **— it was already right.**

**Changed:** `build.gradle` (+1 line), `AnimeTrackerApp.java` (~30 lines), `docker/backend.Dockerfile` (new ~30), `infra/**` (new ~700), `.github/workflows/*.yml` (new ~80), `.dockerignore` (new ~15), minus the broken root `package.json` and the dead `AnimeDAO`.

**The headline finding:** the app was *already* stateless, horizontally scalable, and free of server-side third-party calls. Those three properties — easy to miss when reading the code — are exactly what make this a low-risk migration. The genuinely load-bearing work is **not application code** (≈30 lines) but:

1. **adding a connection pool**, without which the deployment fails under its own health checks; and
2. **reproducing two Nginx behaviours in CloudFront** — the `/api` prefix strip and the SPA fallback — one line each, and the two most likely causes of a broken deployment.

Everything else is mechanical substitution: **`Vagrantfile` → `infra/`, `provision/*.sh` → Dockerfiles + Terraform + GitHub Actions, `anime-db` → RDS, `anime-api` → ECS Fargate, `anime-web` → S3 + CloudFront.**

---

The full report is in `project_info__1.md` (Part 1 complete; Part 2 through §2.7). Note the last append was rejected, so §2.8–§2.13 exist only above — happy to re-append them to the file if you'd like it complete on disk.