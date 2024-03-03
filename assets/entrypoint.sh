#!/bin/sh

replace_commas_with_newlines() {
    echo "$1" | tr ',' '\n' | awk 'NR > 1 { printf "    " } { print }'
}

export CONFIG=${CONFIG:-'/etc/keepalived/keepalived.conf'}
export VRRP_INSTANCE=${VRRP_INSTANCE:-$HOSTNAME}
export INTERFACE=${INTERFACE:-'eth0'}
export IP=$(ifconfig "${INTERFACE}" | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
export UNICAST_SRC_IP=${UNICAST_SRC_IP:-$IP}
export UNICAST_PEERS=${UNICAST_PEERS:-''}
export STATE=${STATE:-'BACKUP'}
export ROUTER_ID=${ROUTER_ID:-'50'}
export PRIORITY=${PRIORITY:-'100'}
export ADVERTISE_INTERVAL=${ADVERTISE_INTERVAL:-'1'}
export VIRTUAL_IPS=${VIRTUAL_IPS:-"192.168.2.100/32 dev $INTERFACE"}
export PASSWORD=${PASSWORD:-'password'}
export NOTIFY=${NOTIFY:-'/notify.sh'}

# Ensure that the template file exists
if [ ! -f "$CONFIG" ]; then
    echo "Template file $CONFIG not found."
    exit 1
fi

# Replace commas in VARIABLES with newlines
if [ -n "$UNICAST_PEERS" ]; then
  UNICAST_PEERS_FMT=$(replace_commas_with_newlines "$UNICAST_PEERS")
else
  UNICAST_SRC_IP_LINE='unicast_src_ip ${UNICAST_SRC_IP}'
  UNICAST_PEER_BLOCK='unicast_peer/,/  }'
  sed -i "/${UNICAST_SRC_IP_LINE}/d" "$CONFIG"
  sed -i "/${UNICAST_PEER_BLOCK}/d" "$CONFIG"
fi

VIRTUAL_IPS_FMT=$(replace_commas_with_newlines "$VIRTUAL_IPS")

if [ -n "$NOTIFY" ]; then
  if [ -e "$NOTIFY" ]; then
      chmod +x "$NOTIFY"
  else
      echo "WARNING: The NOTIFY path '$NOTIFY' does not exist."
  fi
fi


if [ -f "$CONFIG" ]; then
  if  grep -q '${.*}' "$CONFIG"; then
    echo "Configuration file $CONFIG seems to be a template file, templating..."
    TMP_CONFIG=$(mktemp)
    UNICAST_PEERS=$UNICAST_PEERS_FMT;
    VIRTUAL_IPS=$VIRTUAL_IPS_FMT;
    envsubst < $CONFIG > $TMP_CONFIG
    mv "$TMP_CONFIG" "$CONFIG"
  else
    echo "Configuration file $CONFIG is not a template file. nothing to do."
  fi
else
  echo "Configuration file $CONFIG does not exist. Please provide a configuration file."
  exit 1
fi

exec /usr/sbin/keepalived -f "$CONFIG" --dont-fork --log-console ${ARGUMENTS}
