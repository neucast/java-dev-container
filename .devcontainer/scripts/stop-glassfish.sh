#!/usr/bin/env bash
set -euo pipefail

GF_DIR="/opt/glassfish5"
GLASSFISH_HOME="${GF_DIR}/glassfish"
ASADMIN="${GLASSFISH_HOME}/bin/asadmin"
DOMAIN="domain1"

export GLASSFISH_HOME
export AS_JAVA="${JAVA_HOME:-/usr/lib/jvm/java-8-openjdk}"
export PATH="${GLASSFISH_HOME}/bin:${PATH}"

if ! command -v asadmin >/dev/null 2>&1; then
  echo "asadmin not found. Did setup-glassfish.sh run?"
  exit 0
fi

# Stop domain if running
if ${ASADMIN} list-domains | grep -q "${DOMAIN} running"; then
  echo "Stopping ${DOMAIN}..."
  ${ASADMIN} stop-domain ${DOMAIN} || true
else
  echo "${DOMAIN} is not running."
fi

echo "GlassFish stop script finished."