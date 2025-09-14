# Dev Dockerfile for local development of the Java + GlassFish app
# Includes JDK 8 and Maven, installs GlassFish 5, and uses the repo-mounted volume for sources.
# Also includes an optional OpenSSH server so the container can be used remotely over SSH.

FROM maven:3.9-eclipse-temurin-8

# Ensure GlassFish always uses the container JDK 8
ENV AS_JAVA=${JAVA_HOME}

# Install dependencies required by setup/start scripts
USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy and run setup scripts at build time to bake the application server and SSH server into the image
COPY .devcontainer/scripts /tmp/scripts
RUN bash /tmp/scripts/setup-glassfish.sh \
    && bash /tmp/scripts/setup-ssh.sh \
    && rm -rf /tmp/scripts

# Working directory where the project will be bind-mounted via docker-compose
WORKDIR /workspace

# Ports: HTTP 8080, Admin console 4848, SSH 2222
EXPOSE 8080 4848 2222

# Default command: start sshd (runtime-prepared) in background, then start GlassFish and tail logs.
# The start script will build the WAR if it is not yet present.
CMD ["bash", "-lc", "bash .devcontainer/scripts/run-sshd.sh & bash .devcontainer/scripts/start-glassfish.sh && tail -f /opt/glassfish5/glassfish/domains/domain1/logs/server.log"]
