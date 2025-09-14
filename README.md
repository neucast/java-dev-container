# Java Dev Container with GlassFish 5

A ready-to-use development environment for Java web apps based on:
- JDK 8 (Temurin)
- Maven (latest)
- GlassFish 5.1 (Java EE 8 / Servlet 4.0)

Use it with VS Code Dev Containers or IntelliJ IDEA (Dev Containers plugin), or run locally via Docker Compose. The included sample project is a simple WAR with a Hello Servlet and index.jsp.

## What’s inside
- Dev Container configuration (.devcontainer/) for VS Code and JetBrains
- Dockerfile and docker-compose.yml for local development outside IDEs
- Maven webapp (packaging: war), Java 8, JUnit 5 tests
- GlassFish setup and lifecycle scripts to build and deploy the WAR automatically
- Optional OpenSSH server to enable remote development into the running container

## Requirements
- Docker Desktop or Docker Engine + Docker Compose v2
- One of the following for in-IDE container development:
  - VS Code + Dev Containers extension
  - IntelliJ IDEA + Dev Containers plugin

## Quick start (VS Code)
1. Open the folder in VS Code.
2. When prompted, “Reopen in Container” (or run: Command Palette → Dev Containers: Reopen in Container).
3. On first start, the container will:
   - Install GlassFish 5
   - Verify Java and Maven
   - Build the project (mvn -q -DskipTests package)
   - Start GlassFish and deploy the WAR
4. Open your browser:
   - App: http://localhost:8080/app/
   - Hello servlet: http://localhost:8080/app/hello
   - Admin console: http://localhost:4848/

## Quick start (IntelliJ IDEA)
1. Install the “Dev Containers” plugin.
2. Open the project and choose “Open in Dev Container”.
3. The same lifecycle runs as in VS Code: build, start GlassFish, deploy WAR.
4. Use the Run tool window terminal inside the container for Maven commands, etc.

## Quick start (Docker Compose)
If you prefer running the dev environment without an IDE:

```bash
# From the project root
docker compose up --build
```

Then open:
- App: http://localhost:8080/app/
- Hello servlet: http://localhost:8080/app/hello
- GlassFish admin: http://localhost:4848/

The container tails server.log; stop with Ctrl+C.

## Remote development over SSH (optional)
This image includes an OpenSSH server so you can connect from a remote IDE or terminal. SSH configuration (port and password) now honors environment variables at runtime, so overrides passed via docker-compose work without rebuilding.

- Default port: 2222
- Default credentials (change before exposing over the internet):
  - User: dev (set DEV_USER to override)
  - Password: devpass (set DEV_PASSWORD to override)

With Docker Compose, environment variables can be provided via your shell or an .env file:

```bash
DEV_USER=myuser DEV_PASSWORD=strongpass SSH_PORT=2222 docker compose up --build
```

Connect via SSH:

```bash
ssh dev@localhost -p 2222
# or using your overrides
ssh myuser@localhost -p 2222
```

Security note: Do not expose these services publicly without hardening (keys-only SSH, strong passwords, firewalling, and possibly a VPN or reverse proxy).

## Common commands
From within the container (built-in terminal):

- Build without tests: `mvn -q -DskipTests package`
- Run tests: `mvn -q test`
- Redeploy app:
  - The start script undeploys/redeploys on container start. You can also run:
    - `bash .devcontainer/scripts/start-glassfish.sh`
- Stop GlassFish gracefully: `bash .devcontainer/scripts/stop-glassfish.sh`

## Configuration details
- JDK: 8 (Temurin) via devcontainer feature
- Maven: latest via devcontainer feature or maven:3.9-eclipse-temurin-8 base image
- GlassFish: 5.1 installed to /opt/glassfish5
- Exposed ports:
  - 8080 (HTTP)
  - 4848 (Admin console)
  - 2222 (SSH)
- App artifact: `target/app-0.0.1-SNAPSHOT.war` deployed as context path `/app`

## Project structure
- `.devcontainer/` – Dev Container config and scripts
  - `devcontainer.json` – Dev Container definition
  - `scripts/setup-glassfish.sh` – Installs GlassFish
  - `scripts/start-glassfish.sh` – Starts domain1, builds WAR if needed, deploys/redeploys
  - `scripts/stop-glassfish.sh` – Gracefully stops GlassFish
- `Dockerfile` – Image for local development (installs GlassFish and SSH)
- `docker-compose.yml` – Brings up the dev environment with ports and volume mapping
- `pom.xml` – Maven build (packaging: war, Java 11)
- `src/main/java/com/example/` – Java sources (App.java, servlet under `web`)
- `src/main/webapp/` – Web resources (index.jsp)
- `src/test/java/` – JUnit tests

## Troubleshooting
- Port already in use: Change published ports in docker-compose.yml (e.g., `- "8081:8080"`).
- Admin console not reachable: Ensure container is healthy; check logs in the compose terminal or tail `/opt/glassfish5/glassfish/domains/domain1/logs/server.log` inside the container.
- Build issues: Clear `target/` and run `mvn -U clean package`.
- Permissions on mounted volume: `updateRemoteUserUID` is enabled in devcontainer.json to mitigate UID mismatches in IDE dev containers.

## License
This template is provided as-is for development purposes. Add your project’s license here.
