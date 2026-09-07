# Anitracker (Three-VM Internet Movie/Anime Database)

Anitracker is a small web application for tracking an anime watchlist with persistent storage and a browser UI. End users open the web interface, browse seeded entries, and manage records through API-backed actions. The project is designed for reproducible deployment across three virtual machines and can be brought up from a clean clone with one command (see [Quick start](#quick-start)).

## Quick start

```bash
vagrant up
```

Then open: `http://localhost:8080`

---

## 1) Architecture (3 VM requirement)

### VM responsibilities

| VM | Hostname | Responsibility |
|---|---|---|
| Database VM | `anime-db` | Runs PostgreSQL and stores persistent application data (`my_anime` and related schema). |
| API VM | `anime-api` | Runs Java/Jooby backend, exposes `/health`, `/anime`, `/anime/{malId}`, performs validation, reads/writes PostgreSQL. |
| Web VM | `anime-web` | Runs Nginx and serves built Vue frontend, proxies `/api/*` requests to API VM. |

### Request flow (representative user action)

Example: user loads the catalog page.

1. Browser requests `http://localhost:8080` (Web VM).
2. Web VM serves Vue app and proxies `/api/anime` to API VM.
3. API VM queries PostgreSQL on DB VM for stored records.
4. DB VM returns rows to API VM.
5. API VM returns JSON to Web VM.
6. Web VM returns proxied API response to browser UI.

Each representative request path therefore uses all three VMs.

### Network and ports

| Service | Guest endpoint | Host access |
|---|---|---|
| Web (Nginx) | `anime-web:80` | `http://localhost:8080` |
| API (Jooby) | `anime-api:8080` | `http://localhost:8081` |
| PostgreSQL | `anime-db:5432` | `localhost:5433` |

Private VM network: `192.168.56.0/24`  
DB VM: `192.168.56.10` · API VM: `192.168.56.11` · Web VM: `192.168.56.12`

---

## 2) Tools and purpose

- **Vagrant**: defines and provisions all three VMs from one reproducible configuration.
- **VirtualBox**: hypervisor used by Vagrant to create/run guest machines.
- **PostgreSQL**: persistent relational datastore for application records.
- **Java 17 + Jooby**: backend HTTP API and business logic.
- **Vue + Vite**: frontend UI build and static assets.
- **Nginx**: serves frontend files and reverse proxies `/api` traffic to backend.

---

## 3) Supported host environment

### Host OS

- Ubuntu 22.04+ (primary tested environment)
- Windows 10/11 and macOS (supported by tooling; validate locally before submission)

### Required tools

- Vagrant `2.4+`
- VirtualBox `7.x+`
- Git

Node.js and Java are installed inside VMs during provisioning; they are not required on the host for standard deployment.

### Known host constraints

- If VirtualBox shows a turtle icon and VM SSH/provisioning stalls on Windows, disable Hyper-V and reboot before retrying.
- VirtualBox and Guest Additions version mismatches can break `/vagrant` shared folder mounting.

---

## 4) One-command deployment

From repository root:

```bash
vagrant up
```

This command:

- creates/provisions `db`, `api`, and `web` VMs;
- installs required packages in each VM;
- applies schema + seed data in PostgreSQL;
- builds and starts backend service;
- builds frontend and serves it through Nginx.

First deployment is slower because packages, dependencies, and VM resources are downloaded/built.

---

## 5) Verification (reproducible evidence)

Run these commands after deployment:

```bash
# 1) VM state
vagrant status

# 2) Database has seeded rows
vagrant ssh db -- 'PGPASSWORD=AppPass123 psql -h localhost -U app_user -d anitracker -c "SELECT mal_id, title, watch_status FROM my_anime ORDER BY mal_id LIMIT 5;"'

# 3) API health from inside API VM (service listens on 8080 in-VM)
vagrant ssh api -- 'curl -s http://localhost:8080/health'

# 4) Proxied request through Web VM to API VM
vagrant ssh web -- 'curl -s http://localhost/api/anime | head -c 300; echo'

# 5) Web UI reachable from host
curl -I http://localhost:8080
```

Expected indicators:

- `vagrant status` shows all three machines as `running`.
- DB query returns seeded anime rows.
- Health endpoint returns JSON with `"status":"ok"` and `"database":"connected"`.
- `/api/anime` returns JSON array/object data.
- `curl -I` includes `HTTP/1.1 200 OK`.

---

## 6) Removal / cleanup

Destroy all created VM resources:

```bash
vagrant destroy -f
```

Optional post-check:

```bash
vagrant status
```

Expected: machines reported as `not created`.

---

## 7) Demonstration data

- Seeded catalog data is preloaded so useful output is visible immediately after deployment.
- Repository schema file: `schema.sql`
- Repository seed file: `seed_data.sql`
- Inside the DB VM, those files are mounted and applied from `/vagrant/schema.sql` and `/vagrant/seed_data.sql`.

Why this is sufficient:

- The web page can render a non-empty catalog without manual entry.
- API and DB verification commands show persisted rows immediately.

---

## 8) Developer modification and redeployment workflow

Developers edit files in their local Git clone, then reprovision/rebuild only the impacted VM(s).

### Backend change (Java/API or DB access logic)

1. Edit backend source under `backend/src/main/app`.
2. Rebuild/reprovision API VM:

```bash
vagrant provision api
```

3. Re-verify:

```bash
vagrant ssh api -- 'curl -s http://localhost:8080/health'
vagrant ssh web -- 'curl -s http://localhost/api/anime | head -c 200; echo'
```

### Frontend change (Vue UI)

1. Edit frontend source under `frontend/src`.
2. Rebuild/reprovision Web VM:

```bash
vagrant provision web
```

3. Re-verify:

```bash
curl -I http://localhost:8080
vagrant ssh web -- 'curl -s http://localhost/api/anime | head -c 200; echo'
```

### Schema/seed change

1. Edit `schema.sql` and/or `seed_data.sql` in the repository root.
2. Reprovision DB VM:

```bash
vagrant provision db
```

3. Re-run DB + API checks from verification section.

Inside the DB VM, the provisioning scripts apply the files from `/vagrant/schema.sql` and `/vagrant/seed_data.sql`.

---

## 9) Repository structure

- `Vagrantfile` — defines three-VM topology, private network, and forwarded ports.
- `provision/` — VM provisioning scripts:
  - `db_provision.sh`
  - `api_provision.sh`
  - `web_provision.sh`
- `schema.sql` — database schema.
- `seed_data.sql` — demonstration dataset.
- `backend/` — Java/Jooby API.
- `frontend/` — Vue/Vite web client.

---

## 10) Troubleshooting

### VM boot/provision failures

- Check VM state:
  ```bash
  vagrant status
  ```
- Check VirtualBox registration/running VMs:
  ```bash
  VBoxManage list vms
  VBoxManage list runningvms
  ```
- Retry provisioning for a specific VM:
  ```bash
  vagrant provision db
  vagrant provision api
  vagrant provision web
  ```

### `/vagrant` shared folder missing

- Reload VMs:
  ```bash
  vagrant reload
  ```
- Verify VirtualBox and Guest Additions compatibility.

### Service-level checks

- API VM:
  ```bash
  vagrant ssh api -- 'systemctl status anitracker-api.service --no-pager'
  vagrant ssh api -- 'journalctl -u anitracker-api.service -n 50 --no-pager'
  ```
- Web VM:
  ```bash
  vagrant ssh web -- 'nginx -t'
  ```
- DB reachability:
  ```bash
  vagrant ssh db -- 'pg_isready -h 127.0.0.1 -p 5432 -d anitracker'
  ```

---

## 11) Assessment evidence pointers

- **Deployment command**: `vagrant up` (Quick start / One-command deployment).
- **Verification commands**: section “Verification (reproducible evidence)”.
- **Destroy command**: section “Removal / cleanup” (`vagrant destroy -f`).
- **Seeded data files**: `schema.sql`, `seed_data.sql`.
- **Architecture/provisioning files**: `Vagrantfile`, `provision/*.sh`.

---

## 12) API behavior notes

- Current backend endpoints include `/health`, `/anime`, and `/anime/{malId}`.
- The README does not assume active runtime AniList enrichment or a `502` path for that integration, because that behavior is currently not enabled in the backend implementation.

---

## 13) AI/reuse attribution note
AI has been used to check and rework read me.
Repository implementation is based on project-authored code and standard open-source tooling/libraries referenced in source files and build configs.
