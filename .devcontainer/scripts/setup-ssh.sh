#!/usr/bin/env bash
set -euo pipefail

# This script installs and configures OpenSSH server inside the image so the container
# can be accessed remotely by IDEs/tools over SSH (e.g., for remote development).
# It is intended to run at image build time from the Dockerfile.

# Defaults can be overridden at runtime via environment variables.
DEV_USER="${DEV_USER:-dev}"
DEV_UID="${DEV_UID:-1000}"
DEV_GID="${DEV_GID:-1000}"
DEV_PASSWORD="${DEV_PASSWORD:-devpass}"
SSH_PORT="${SSH_PORT:-2222}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends openssh-server
rm -rf /var/lib/apt/lists/*

# Ensure ssh runtime dir
mkdir -p /var/run/sshd

# Create or reuse group/user safely (avoid UID/GID conflicts present in base images)
# 1) Determine if a user with the requested UID already exists; if so, reuse it.
EXISTING_USER_BY_UID="$(getent passwd "$DEV_UID" | cut -d: -f1 || true)"
if [ -n "$EXISTING_USER_BY_UID" ]; then
  DEV_USER="$EXISTING_USER_BY_UID"
  # Also resolve the primary group from /etc/passwd for this user
  EXISTING_GID="$(getent passwd "$DEV_USER" | cut -d: -f4 || true)"
  if [ -n "$EXISTING_GID" ]; then
    DEV_GID="$EXISTING_GID"
  fi
else
  # Ensure group exists (by GID or by name); if GID is taken, reuse that group
  EXISTING_GROUP_BY_GID="$(getent group "$DEV_GID" | cut -d: -f1 || true)"
  if [ -n "$EXISTING_GROUP_BY_GID" ]; then
    DEV_GROUP_NAME="$EXISTING_GROUP_BY_GID"
  else
    DEV_GROUP_NAME="$DEV_USER"
    groupadd -g "$DEV_GID" "$DEV_GROUP_NAME" || true
  fi

  # Create user if missing; if the name exists, don't try to recreate
  if ! id -u "$DEV_USER" >/dev/null 2>&1; then
    # If requested UID is already taken by some other name (race), avoid specifying -u
    if getent passwd "$DEV_UID" >/dev/null 2>&1; then
      useradd -m -g "$DEV_GROUP_NAME" -s /bin/bash "$DEV_USER"
    else
      useradd -m -u "$DEV_UID" -g "$DEV_GROUP_NAME" -s /bin/bash "$DEV_USER"
    fi
  fi
fi

# Ensure the user has a shell and home directory
usermod -s /bin/bash "$DEV_USER" >/dev/null 2>&1 || true
HOME_DIR="$(getent passwd "$DEV_USER" | cut -d: -f6 || true)"
if [ -n "$HOME_DIR" ] && [ ! -d "$HOME_DIR" ]; then
  mkdir -p "$HOME_DIR" && chown -R "$DEV_USER":"$DEV_GID" "$HOME_DIR" || true
fi

# Set (or reset) password for the resolved user
if [ -n "$DEV_USER" ]; then
  echo "$DEV_USER:$DEV_PASSWORD" | chpasswd
fi

# Allow password login by default (for simple remote dev). Users should change password or use keys.
sed -ri 's/^#?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -ri 's/^#?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -ri 's/^#?UsePAM .*/UsePAM yes/' /etc/ssh/sshd_config

# Set port
if grep -qE '^#?Port ' /etc/ssh/sshd_config; then
  sed -ri "s/^#?Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config
else
  echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config
fi

# Harden keepalive a bit for long-lived IDE sessions
if ! grep -q '^ClientAliveInterval' /etc/ssh/sshd_config; then
  echo 'ClientAliveInterval 60' >> /etc/ssh/sshd_config
fi
if ! grep -q '^ClientAliveCountMax' /etc/ssh/sshd_config; then
  echo 'ClientAliveCountMax 5' >> /etc/ssh/sshd_config
fi

# Generate host keys if missing (at build time; they can also regenerate at runtime)
/usr/bin/ssh-keygen -A

# Helpful message
echo "OpenSSH configured. User: ${DEV_USER}, Port: ${SSH_PORT}. Change DEV_PASSWORD for security."