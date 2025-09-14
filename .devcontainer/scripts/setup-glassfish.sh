#!/usr/bin/env bash
set -euo pipefail

GLASSFISH_VERSION=5.1.0
INSTALL_DIR="/opt"
GF_DIR="${INSTALL_DIR}/glassfish5"

if command -v asadmin >/dev/null 2>&1 && [ -d "$GF_DIR" ]; then
  echo "GlassFish appears to be installed at ${GF_DIR}. Skipping install."
  exit 0
fi

# Install prerequisites
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends curl unzip ca-certificates
rm -rf /var/lib/apt/lists/*

# Download and install GlassFish
TMP_ZIP="/tmp/glassfish.zip"

# Candidate sources (primary first, then fallbacks)
CANDIDATES=(
  "https://repo1.maven.org/maven2/org/glassfish/main/distributions/glassfish/${GLASSFISH_VERSION}/glassfish-${GLASSFISH_VERSION}.zip"
  "https://download.eclipse.org/ee4j/glassfish/${GLASSFISH_VERSION}/glassfish-${GLASSFISH_VERSION}.zip"
  "https://archive.eclipse.org/ee4j/glassfish/${GLASSFISH_VERSION}/glassfish-${GLASSFISH_VERSION}.zip"
  "https://github.com/eclipse-ee4j/glassfish/releases/download/${GLASSFISH_VERSION}/glassfish-${GLASSFISH_VERSION}.zip"
)

SUCCESS=0
for url in "${CANDIDATES[@]}"; do
  echo "Attempting to download GlassFish ${GLASSFISH_VERSION} from ${url}..."
  if curl -fSL --retry 5 --retry-delay 2 "${url}" -o "${TMP_ZIP}"; then
    SUCCESS=1
    break
  else
    echo "Download failed from ${url}. Trying next source..." >&2
  fi
done

if [ "$SUCCESS" -ne 1 ]; then
  echo "ERROR: Unable to download GlassFish ${GLASSFISH_VERSION} from all known sources." >&2
  exit 1
fi

mkdir -p "${INSTALL_DIR}"
unzip -q -o "${TMP_ZIP}" -d "${INSTALL_DIR}"
rm -f "${TMP_ZIP}"

# Do not create a global asadmin symlink; it breaks relative path resolution of asenv.conf
# Instead, always invoke ${GF_DIR}/glassfish/bin/asadmin directly from scripts.

# Print version via full path (ignore failures in build environment)
"${GF_DIR}/glassfish/bin/asadmin" version || true
# Touch jspawnhelper to avoid potential permission issues (ignore if missing)
"${GF_DIR}/jdk/lib/jspawnhelper" >/dev/null 2>&1 || true

echo "GlassFish installed at ${GF_DIR}."
