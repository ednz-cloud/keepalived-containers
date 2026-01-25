#!/bin/sh

export CONFIG=${CONFIG:-'/etc/conntrackd/conntrackd.conf'}
export SYNC_MODE=${SYNC_MODE:-'FTFW'}
export INTERFACE=${INTERFACE:-'eth0'}

# Auto-detect local IP if not set
if [ -z "$IPV4_ADDRESS" ]; then
  IPV4_ADDRESS=$(ip -4 addr show "${INTERFACE}" | awk '/inet / {print $2}' | cut -d'/' -f1 | head -1)
  if [ -z "$IPV4_ADDRESS" ]; then
    echo "ERROR: Could not auto-detect IPV4_ADDRESS for interface ${INTERFACE}"
    exit 1
  fi
fi
export IPV4_ADDRESS

# IPV4_DESTINATION_ADDRESS is required
if [ -z "$IPV4_DESTINATION_ADDRESS" ]; then
  echo "ERROR: IPV4_DESTINATION_ADDRESS environment variable is required"
  exit 1
fi
export IPV4_DESTINATION_ADDRESS

export SYNC_PORT=${SYNC_PORT:-'3780'}
export HASH_SIZE=${HASH_SIZE:-'32768'}
export HASH_LIMIT=${HASH_LIMIT:-'131072'}
export SOCKET_PATH=${SOCKET_PATH:-'/var/run/conntrackd/conntrackd.ctl'}

# Ensure socket directory exists
SOCKET_DIR=$(dirname "$SOCKET_PATH")
mkdir -p "$SOCKET_DIR"

# Ensure that the template file exists
if [ ! -f "$CONFIG" ]; then
  echo "Configuration file $CONFIG not found."
  exit 1
fi

if grep -q '${.*}' "$CONFIG"; then
  echo "Configuration file $CONFIG seems to be a template file, templating..."
  TMP_CONFIG=$(mktemp)
  envsubst <"$CONFIG" >"$TMP_CONFIG"
  mv "$TMP_CONFIG" "$CONFIG"
else
  echo "Configuration file $CONFIG is not a template file, nothing to do."
fi

echo "Starting conntrackd with config: $CONFIG"
exec /usr/sbin/conntrackd -C "$CONFIG" ${ARGUMENTS}
