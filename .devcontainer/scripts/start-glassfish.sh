#!/usr/bin/env bash
set -euo pipefail

GF_DIR="/opt/glassfish5"
GLASSFISH_HOME="${GF_DIR}/glassfish"
ASADMIN="${GLASSFISH_HOME}/bin/asadmin"
APP_WAR="$(pwd)/target/app-0.0.1-SNAPSHOT.war"
APP_NAME="app"

# Ensure GlassFish resolves its home and Java properly
export GLASSFISH_HOME
export AS_JAVA="${JAVA_HOME:-/usr/lib/jvm/java-8-openjdk}"
export PATH="${GLASSFISH_HOME}/bin:${PATH}"

if ! command -v asadmin >/dev/null 2>&1; then
  echo "asadmin not found. Did setup-glassfish.sh run?"
  exit 1
fi

# Start domain if not running
if ! ${ASADMIN} list-domains | grep -q "domain1 running"; then
  echo "Starting domain1..."
  ${ASADMIN} start-domain domain1
fi

# Wait for server to be ready (admin on 4848)
for i in {1..60}; do
  if curl -fsS http://localhost:4848 >/dev/null 2>&1; then
    break
  fi
  sleep 1
  if [ "$i" -eq 60 ]; then
    echo "GlassFish admin did not become ready in time." >&2
  fi
done

# Build WAR if not present
if [ ! -f "$APP_WAR" ]; then
  echo "Building WAR..."
  mvn -q -DskipTests package
fi

# If app already deployed, redeploy
if ${ASADMIN} list-applications | grep -q "\b${APP_NAME}\b"; then
  echo "Undeploying existing ${APP_NAME}..."
  ${ASADMIN} undeploy ${APP_NAME} || true
fi

echo "Deploying ${APP_WAR}..."
${ASADMIN} deploy --name ${APP_NAME} --force=true "${APP_WAR}"

echo "Application deployed. Try http://localhost:8080/${APP_NAME}/"
