# COSC349 Assignment Report (Summary)

## Tooling and VM responsibility decisions

- **Vagrant + VirtualBox** was chosen for local reproducibility and one-command deployment (`vagrant up`).
- **frontend VM** serves a simple Vue app via Nginx and proxies `/api` requests.
- **api VM** runs a Java Jooby service with JDBI-based SQL access.
- **db VM** runs PostgreSQL and stores persistent movie data.

This split makes responsibilities clear and independently replaceable while preserving end-to-end behavior.

## Why separate VMs?

Benefits:
- clearer boundaries between UI, business logic, and data;
- easier component-level redeployment and debugging;
- closer to real multi-tier deployments.

Tradeoffs:
- additional provisioning complexity;
- higher startup/download cost than a single server.

## Reproducibility evidence

- Deploy command: `vagrant up`
- Verify command: `./scripts/verify.sh`
- Remove command: `./scripts/destroy.sh`

The verify script checks VM state and performs a cross-VM movie query initiated from the frontend VM.

## Downloaded components and estimated data volume

Approximate clean-build downloads:
- `ubuntu/jammy64` base box: ~0.8–1.2 GB (compressed box + metadata)
- apt packages across VMs (JDK, Maven, PostgreSQL, Nginx, dependencies): ~0.6–1.1 GB
- Maven dependencies for backend build: ~80–200 MB

Estimated clean total: **~1.5–2.5 GB**.

Estimated redeploy (`vagrant provision`) total:
- usually apt metadata + any package updates + incremental Maven checks: **~50–300 MB**.

Precision note: these are range estimates and vary by mirror, existing host caches, and package update timing.

## Two developer changes and rebuild flow

1. **UI behavior change** (e.g., change default sort order in `/frontend/index.html`).
   - Rebuild/rerun: `vagrant provision frontend`
   - Check: refresh `http://localhost:8081`, then run `./scripts/verify.sh`

2. **Backend/API change** (e.g., add a field to movie response in `/backend/src/main/java/imdb`).
   - Rebuild/rerun: `vagrant provision api` (and `vagrant provision db` if schema/data changed)
   - Check: `curl http://localhost:8080/api/movies` and `./scripts/verify.sh`

## Debugging/deployment problem investigated

Potential SQL-ordering injection risk from user-supplied `sort` was addressed by mapping accepted sort values through a strict whitelist (`MovieSort`) before embedding the SQL column name.

## AI use statement

AI tools were used for drafting and refining deployment/configuration code and documentation. Output was reviewed and edited for correctness, and security-sensitive handling (credentials/secrets) was kept out of committed files beyond non-sensitive local dev defaults.
