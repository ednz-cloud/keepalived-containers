#!/bin/sh
#
# Test script for HA failover with conntrack sync
#
# Run from the examples/ directory:
#   sudo podman-compose -f docker-compose.local-test.yml up -d
#   ./test-failover.sh

set -e

VIP="172.20.0.100"
COMPOSE_FILE="docker-compose.local-test.yml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { printf "${GREEN}[TEST]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

# Check if running as root (needed for podman network access)
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    error "This script needs root to access the podman network"
    echo "Run: sudo $0"
    exit 1
  fi
}

# Wait for services to be ready
wait_ready() {
  log "Waiting for services to be ready..."
  sleep 5

  for i in 1 2 3 4 5; do
    if podman exec conntrackd-node1 conntrackd -C /etc/conntrackd/conntrackd.conf -s >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done
}

# Query VIP and show which node responds
# Uses curl from inside conntrackd container so connections are tracked
query_vip() {
  response=$(podman exec conntrackd-node1 curl -s --connect-timeout 2 "http://${VIP}/" 2>/dev/null || \
             podman exec conntrackd-node2 curl -s --connect-timeout 2 "http://${VIP}/" 2>/dev/null || \
             echo "FAILED")
  echo "$response"
}

# Show conntrack stats
show_conntrack_stats() {
  log "Conntrack stats for node1:"
  podman exec conntrackd-node1 conntrackd -C /etc/conntrackd/conntrackd.conf -s 2>/dev/null | grep -A2 "cache\|UDP traffic" || true

  log "Conntrack stats for node2:"
  podman exec conntrackd-node2 conntrackd -C /etc/conntrackd/conntrackd.conf -s 2>/dev/null | grep -A2 "cache\|UDP traffic" || true
}

# Show which node has VIP
show_vip_owner() {
  log "Checking VIP ownership..."
  if podman exec conntrackd-node1 ip addr show eth0 2>/dev/null | grep -q "${VIP}"; then
    echo "  VIP ${VIP} is on: node1"
  elif podman exec conntrackd-node2 ip addr show eth0 2>/dev/null | grep -q "${VIP}"; then
    echo "  VIP ${VIP} is on: node2"
  else
    warn "VIP ${VIP} not found on either node"
  fi
}

# Main test sequence
main() {
  check_root

  log "=== HA Failover Test ==="
  echo

  wait_ready

  log "Initial state:"
  show_vip_owner

  log "Querying VIP (http://${VIP}/)..."
  response=$(query_vip)
  echo "  Response: ${response}"
  echo

  log "Generating some traffic for conntrack..."
  for i in 1 2 3 4 5; do
    podman exec conntrackd-node1 curl -s --connect-timeout 2 "http://${VIP}/" >/dev/null 2>&1 || true
    podman exec conntrackd-node2 curl -s --connect-timeout 2 "http://${VIP}/" >/dev/null 2>&1 || true
  done

  log "Current connections in kernel conntrack table (node1):"
  podman exec conntrackd-node1 conntrack -L 2>/dev/null || true
  echo

  show_conntrack_stats
  echo

  log "Stopping keepalived-node1 to trigger failover..."
  podman stop keepalived-node1 >/dev/null
  sleep 3

  log "After failover:"
  show_vip_owner

  log "Querying VIP after failover..."
  response=$(query_vip)
  echo "  Response: ${response}"
  echo

  show_conntrack_stats
  echo

  log "Restarting keepalived-node1..."
  podman start keepalived-node1 >/dev/null
  sleep 3

  log "After node1 returns:"
  show_vip_owner

  log "Querying VIP after node1 returns..."
  response=$(query_vip)
  echo "  Response: ${response}"
  echo

  log "=== Test Complete ==="
}

main "$@"
