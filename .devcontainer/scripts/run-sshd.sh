#!/usr/bin/env bash
set -euo pipefail

# Runtime SSH launcher to ensure SSH is actually reachable.
# Applies runtime env overrides and ensures required runtime dirs/keys exist.

DEV_USER="${DEV_USER:-dev}"
DEV_PASSWORD="${DEV_PASSWORD:-devpass}"
SSH_PORT="${SSH_PORT:-2222}"

# Ensure runtime dir exists (it's tmpfs and not preserved from build layers)
mkdir -p /var/run/sshd

# Ensure host keys exist (containers can be ephemeral)
if ! ls /etc/ssh/ssh_host_* 1>/dev/null 2>&1; then
  /usr/bin/ssh-keygen -A
fi

# Apply Port from env at runtime so docker-compose overrides take effect
if grep -qE '^#?Port ' /etc/ssh/sshd_config; then
  sed -ri "s/^#?Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config
else
  echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config
fi

# If the user exists, refresh its password from env (idempotent)
if id -u "$DEV_USER" >/dev/null 2>&1; then
  echo "$DEV_USER:$DEV_PASSWORD" | chpasswd || true
fi

# Start sshd in foreground (callers may background this script if desired)
exec /usr/sbin/sshd -D
