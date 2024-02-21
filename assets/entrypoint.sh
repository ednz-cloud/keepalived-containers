#!/bin/sh
replace_commas_with_newlines() {
    echo "$1" | tr ',' '\n' | awk 'NR > 1 { printf "    " } { print }'
}

export IP=$(ifconfig "${INTERFACE}" | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
export CONFIG=${CONFIG:-/etc/keepalived/keepalived.conf}
export VRRP_INSTANCE=${VRRP_INSTANCE:-$HOSTNAME}
export VIP_INTERFACE=${VIP_INTERFACE:-$INTERFACE}
export UNICAST_SRC_IP=${UNICAST_SRC_IP:-$IP}

# Ensure that the template file exists
if [ ! -f "$CONFIG" ]; then
    echo "Template file $CONFIG not found."
    exit 1
fi

# Replace commas in UNICAST_PEERS with newlines
UNICAST_PEERS_FMT=$(replace_commas_with_newlines "$UNICAST_PEERS")

if [ -f "$CONFIG" ]; then
  if  grep -q '${.*}' "$CONFIG"; then
    echo "Configuration file $CONFIG seems to be a template file, templating..."
    TMP_CONFIG=$(mktemp)
    UNICAST_PEERS=$UNICAST_PEERS_FMT; envsubst < $CONFIG > $TMP_CONFIG
    mv "$TMP_CONFIG" "$CONFIG"
  else
    echo "Configuration file $CONFIG is not a template file. nothing to do."
  fi
else
  echo "Configuration file $CONFIG does not exist. Please provide a configuration file."
  exit 1
fi

exec /usr/sbin/keepalived -f "$CONFIG" --dont-fork --log-console ${ARGUMENTS}
