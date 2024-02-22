#!/bin/bash

ENDSTATE=$3
NAME=$2
TYPE=$1

case $ENDSTATE in
  "BACKUP")
    exit 0
    ;;
  "FAULT")
    exit 0
    ;;
  "MASTER")
    exit 0
    ;;
  *) echo "Unknown state ${ENDSTATE} for VRRP ${TYPE} ${NAME}"
    exit 1
    ;;
esac
