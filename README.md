# Internet Movie Database (Simple 3-VM Deployment)

A minimal IMDB-like movie tracker built for local virtualised deployment.

## Architecture

The system uses **three VMs**, each with a separate responsibility:

1. **frontend** (Nginx + Vue app): user interface with two pages (movie list + movie details).
2. **api** (Java Jooby + JDBI): backend API that handles movie list/detail requests.
3. **db** (PostgreSQL): persistent movie data store.

Every movie request flows through all VMs:

`Browser -> frontend VM -> api VM -> db VM -> api VM -> frontend VM -> Browser`

## Supported host environment

- Host OS: Linux/macOS/Windows with VirtualBox support
- Vagrant: 2.3+
- VirtualBox: 7+
- Internet access for first-time package/box downloads

## One-command deploy

From repository root:

```bash
vagrant up
```

## Verify deployment

```bash
./scripts/verify.sh
```

What this checks:
- all three VMs are running;
- frontend can trigger a movie API request through the API (which reads stored DB data);
- frontend is reachable at `http://localhost:8081`.

## Remove all created resources

```bash
./scripts/destroy.sh
```

## Application URLs

- Frontend UI: `http://localhost:8081`
- API (host-forwarded): `http://localhost:8080/api/movies`

## Developer modification workflow

Change files in your local clone and rebuild with:

```bash
vagrant provision
```

Then verify again:

```bash
./scripts/verify.sh
```

## Repository layout

- `/frontend`: Vue single-page interface and Nginx site config
- `/backend`: Java Jooby + JDBI API
- `/db`: schema and seed data
- `/provision`: VM provisioning scripts
- `/scripts`: verify and teardown helpers
