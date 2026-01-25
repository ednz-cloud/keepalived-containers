#!/bin/sh
#
# notify-conntrackd.sh - Notify script for keepalived to sync connection tracking
#
# This script should be used as the NOTIFY script in keepalived configuration
# to synchronize connection tracking state between nodes during failover.
#
# Usage: Set NOTIFY=/notify-conntrackd.sh in keepalived environment
#
# The conntrackd socket must be accessible at the configured SOCKET_PATH
# (default: /var/run/conntrackd/conntrackd.ctl)
#
# Mount the conntrackd socket volume in keepalived container:
#   volumes:
#     - conntrackd-socket:/var/run/conntrackd:ro

CONNTRACKD_CONFIG=${CONNTRACKD_CONFIG:-'/etc/conntrackd/conntrackd.conf'}
CONNTRACKD_SOCKET=${CONNTRACKD_SOCKET:-'/var/run/conntrackd/conntrackd.ctl'}

TYPE=$1
NAME=$2
STATE=$3

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') notify-conntrackd: $1"
}

# Check if conntrackd socket exists
if [ ! -S "$CONNTRACKD_SOCKET" ]; then
  log "WARNING: conntrackd socket not found at $CONNTRACKD_SOCKET"
  log "Ensure conntrackd container is running and socket volume is mounted"
  exit 0
fi

case "$STATE" in
  MASTER)
    log "Transitioning to MASTER state"
    # Commit the external cache to the kernel
    conntrackd -C "$CONNTRACKD_CONFIG" -c
    if [ $? -eq 0 ]; then
      log "Committed external cache to kernel"
    else
      log "WARNING: Failed to commit external cache"
    fi
    # Flush the internal and external caches
    conntrackd -C "$CONNTRACKD_CONFIG" -f
    if [ $? -eq 0 ]; then
      log "Flushed caches"
    else
      log "WARNING: Failed to flush caches"
    fi
    # Resync with kernel
    conntrackd -C "$CONNTRACKD_CONFIG" -R
    if [ $? -eq 0 ]; then
      log "Resync with kernel completed"
    else
      log "WARNING: Failed to resync with kernel"
    fi
    ;;
  BACKUP)
    log "Transitioning to BACKUP state"
    # Request synchronization from peer
    conntrackd -C "$CONNTRACKD_CONFIG" -B
    if [ $? -eq 0 ]; then
      log "Requested bulk sync from peer"
    else
      log "WARNING: Failed to request bulk sync"
    fi
    ;;
  FAULT)
    log "Transitioning to FAULT state"
    # Request synchronization from peer
    conntrackd -C "$CONNTRACKD_CONFIG" -B
    if [ $? -eq 0 ]; then
      log "Requested bulk sync from peer"
    else
      log "WARNING: Failed to request bulk sync"
    fi
    ;;
  *)
    log "Unknown state: $STATE"
    ;;
esac

exit 0
