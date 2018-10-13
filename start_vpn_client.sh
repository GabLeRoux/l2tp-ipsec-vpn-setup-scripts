#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $DIR/loadenv.sh
loadenv

if [ -z ${CONNECTION_NAME+x} ]; then echo "CONNECTION_NAME must be set"; exit -1; fi

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

set -x
set -e

ipsec stop || true
ipsec start
systemctl stop xl2tpd || true
systemctl start xl2tpd

sleep 5

ipsec auto --up $CONNECTION_NAME
echo "c vpn-connection" > /var/run/xl2tpd/l2tp-control

sleep 5

ipsec verify || true
ip link
curl https://checkip.amazonaws.com/