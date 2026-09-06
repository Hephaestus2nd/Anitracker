# Anitracker

This repository implements a three-VM application for tracking anime watchlists. The database VM stores the persistent catalogue, the API VM serves the application logic, and the web VM presents a simple interface for end users.

## Architecture

- Database VM: PostgreSQL instance on `192.168.56.10`.
  - Stores the `my_anime` table and seeded demo records.
  - Handles durable application state.
- API VM: Java + Jooby service on `192.168.56.11:8080`.
  - Reads and writes the persisted list via JDBC.
  - Exposes `/health`, `/anime`, and `/anime/{id}` endpoints.
- Web VM: Nginx + Vue frontend on `192.168.56.12` and host port `8080`.
  - Renders a lightweight UI from the API results.
  - Proxies `/api` requests to the Java service.

## Tools used

- Vagrant: provisions and wires the three VMs from one configuration file.
- VirtualBox: the local hypervisor used by Vagrant to create the guest machines.
- PostgreSQL: persistent relational storage for important application data.
- Java 17 + Jooby: backend API and business logic.
- Vue + Vite: browser UI for a user-friendly interface.
- Nginx: static file serving and reverse proxy.

## Supported host environment

- Host OS: Ubuntu, Debian, or macOS with VirtualBox and Vagrant installed.
- Required versions:
  - Vagrant 2.4+
  - VirtualBox 7.x+
  - Node.js 22+ for local frontend rebuilds
  - Java 17+

## One-command deployment

From the repository root:

```bash
vagrant up
```

This provisions the three machines and runs the API and frontend services automatically.
It might take a long time to start up. the API vm might take more than 10 minutes to the point that it may time out.


## Vagrant troubleshooting

1. Check VM state:

    vagrant status

2. Check VirtualBox:

    VBoxManage list vms
    VBoxManage list runningvms

3. If VBoxManage isn't in PATH on Windows, use:

    "/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" list vms

4. If VirtualBox reports "<inaccessible>", investigate/remove
   the stale VM registration before debugging the application. By unregistering it

5. If Vagrant reaches the provisioning stage but the app doesn't work,
   check the relevant VM:

    vagrant ssh db
    vagrant ssh api
    vagrant ssh web

6. Test the services individually:

    API:
    curl http://localhost:8080/health

    DB:
    pg_isready -h 192.168.56.10 -p 5432 -d anitracker

    Web:
    curl http://localhost

   
## Provisioning scripts

Vagrant runs one script on each VM during `vagrant up`:

- `provision/db_provision.sh` installs PostgreSQL, creates the `anitracker` database and `app_user`, allows connections from the private network, and loads `schema.sql` and `seed_data.sql`.
- `provision/api_provision.sh` installs Java and Gradle, copies the backend to `/opt/anitracker`, builds the distribution, and starts `anitracker-api.service`.
- `provision/web_provision.sh` installs Nginx and Node.js, builds the Vue frontend with `npm ci` and `npm run build`, and serves the generated `dist` files from `/var/www/anitracker`.

To run provisioning again after changing a script:

```bash
vagrant provision
```

The database script can be run repeatedly: the schema creation is guarded and the seed data uses conflict handling for existing anime records.

## Verification

After deployment, verify the VMs and request flow:

```bash
vagrant status
vagrant ssh db -- 'psql -h localhost -U app_user -d anitracker -c "SELECT mal_id, title, watch_status FROM my_anime;"'
vagrant ssh api -- 'curl -s http://localhost:8080/health'
vagrant ssh web -- 'curl -s http://localhost/api/anime | head'
curl -I http://localhost:8080
```
'Password is: AppPass123'

The database should show seeded anime entries, the API should return a health payload, and the web VM should return anime data through the proxied `/api` route.

### Adding anime

`POST /anime` accepts an `Anime` JSON object containing `malId`, `title`,
`watchStatus`, episode counts, and the Jikan metadata fields used by the
catalogue. The API validates the identifiers and watch status, defaults
missing progress to zero, caps progress at the known total episode count, and
queries AniList by MAL ID. The AniList `bannerImage` is merged into
`backgroundImageUrl` before the record is saved. AniList failures return
`502 Bad Gateway`; invalid submissions return `400 Bad Request`.

Useful service checks from the relevant VM:

```bash
vagrant ssh api -- 'systemctl status anitracker-api.service --no-pager'
vagrant ssh api -- 'journalctl -u anitracker-api.service -n 50 --no-pager'
vagrant ssh web -- 'nginx -t'
```

## Removal

```bash
vagrant destroy -f
```

## Representative developer change

A realistic change is adding a new field like `score` to the catalog and displaying it in the web UI.

1. Update the PostgreSQL schema and seed file.
2. Extend the `Anime` bean and JDBI mapper.
3. Rebuild the service on the API VM with `gradle build` and restart the service.
4. Refresh the frontend and reload the browser to confirm the new field appears.

Example rebuild command:

```bash
vagrant reload api
vagrant ssh api -- 'cd /opt/anitracker && gradle build && systemctl restart anitracker-api.service'
```

## Repository notes

- `Vagrantfile` defines the three-machine topology.
- `provision/*.sh` installs the packages and configures each VM.
- `schema.sql` and `seed_data.sql` provide the seeded demonstration data.
- `backend` holds the API logic and database access layer.
- `frontend` contains the user-facing Vue application.

## AI and attribution statement

This project was built with standard Git and local project files. No external AI-generated code was used as the primary implementation; the repository work was created and verified by the project team. Any reused ideas are limited to the project’s own original implementation and standard library examples.

## Design justification

The storage responsibility is isolated to PostgreSQL so the database remains authoritative and durable. The API VM handles business logic and network-facing requests, while the web VM focuses on presentation and user interaction. Keeping these tasks separate makes the system easier to scale, debug, and redeploy than a single-server monolith.

The tradeoff is extra complexity: three VMs require more provisioning, more network configuration, and more attention to service startup order. In exchange, the architecture is clearer, more resilient, and closer to a real production deployment pattern.

## Evidence and redevelopment notes

A successful rebuild should produce a working backend API and at least one backed request returning seeded data. A clean deployment is reproducible via `vagrant up`, and a full teardown is handled through `vagrant destroy -f`.
