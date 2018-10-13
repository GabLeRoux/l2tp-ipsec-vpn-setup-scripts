#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $DIR/loadenv.sh
loadenv

if [ -z ${VPN_SERVER_IP+x} ]; then echo "VPN_SERVER_IP must be set"; exit -1; fi
if [ -z ${VPN_IPSEC_PSK+x} ]; then echo "VPN_IPSEC_PSK must be set"; exit -1; fi
if [ -z ${VPN_USER+x} ]; then echo "VPN_USER must be set"; exit -1; fi
if [ -z ${VPN_PASSWORD+x} ]; then echo "VPN_PASSWORD must be set"; exit -1; fi
if [ -z ${CONNECTION_NAME+x} ]; then echo "CONNECTION_NAME must be set"; exit -1; fi
if [ -z ${LOCAL_IP+x} ]; then echo "LOCAL_IP must be set"; exit -1; fi
if [ -z ${INSTALL_PACKAGES+x} ]; then echo "INSTALL_PACKAGES must be set"; exit -1; fi
if [ -z ${SERVER_USES_PAP_AUTHENTICATION+x} ]; then echo "SERVER_USES_PAP_AUTHENTICATION must be set"; exit -1; fi
if [ -z ${LOCAL_DEVICE+x} ]; then echo "LOCAL_DEVICE must be set"; exit -1; fi

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

set -x
set -e


if [ "$INSTALL_PACKAGES" -eq 1 ]; then
    echo "Installing packages"
    #yum update -y || true
    yum -y install epel-release
    ##rpm -Uvh -y epel-release*rpm
    yum install -y xl2tpd
    yum install -y openswan
    yum install -y curl
fi

cat > /etc/ipsec.conf <<EOF
config setup
     virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12
## commented as obsolete keyword
#     nat_traversal=yes
# default is auto, which will try netkey first
     protostack=netkey
## commented as obsolete keyword
## you can left "off" (default value) instead
#     oe=no
## commented as obsolete keyword
## Replace eth0 with your network interface
#     plutoopts="--interface=eth0"
conn $CONNECTION_NAME
     authby=secret
     pfs=no
     auto=add
     keyingtries=3
     dpddelay=30
     dpdtimeout=120
     dpdaction=clear
     rekey=yes
     ikelifetime=8h
     keylife=1h
     type=transport
# Replace %any below with your local IP address (private, behind NAT IP is okay as well)
     left=$LOCAL_IP
     leftprotoport=17/1701
# Replace IP address with your VPN server's IP
     right=$VPN_SERVER_IP
     rightprotoport=17/1701
EOF

cat > /etc/ipsec.secrets <<EOF
$LOCAL_IP $VPN_SERVER_IP : PSK "$VPN_IPSEC_PSK"
EOF

ipsec stop || true
ipsec start

sleep 5

ipsec auto --add $CONNECTION_NAME

# At this point the IPsec configuration is complete and we can move on to the L2TP configuration.

cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[lac vpn-connection]
lns = $VPN_SERVER_IP
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF

# If your VPN server uses PAP authentication, replace `require-mschap-v2` with `require-pap`.
if [ "$SERVER_USES_PAP_AUTHENTICATION" -eq 0 ]; then
  L2TP_CLIENT_REQUIRE=require-mschap-v2
else
  L2TP_CLIENT_REQUIRE=require-pap
fi

cat > /etc/ppp/options.l2tpd.client <<EOF
ipcp-accept-local
ipcp-accept-remote
refuse-eap
$L2TP_CLIENT_REQUIRE
noccp
noauth
idle 1800
mtu 1410
mru 1410
defaultroute
usepeerdns
debug
connect-delay 5000
name $VPN_USER
password $VPN_PASSWORD
EOF

mkdir -p /var/run/xl2tpd || true
touch /var/run/xl2tpd/l2tp-control

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

if [ "$ROUTE_ALL_TRAFFIC" -eq 1 ]; then
  echo "route all traffic not yet supported, refer to doc and do it manually or send me a PR"
  echo "Visit https://wiki.archlinux.org/index.php/Openswan_L2TP/IPsec_VPN_client_setup#Routing and finish your setup"
  #ip route add $VPN_SERVER_IP via $LOCAL_IP dev $LOCAL_DEVICE
  #ip route add default via $LOCAL_IP dev $LOCAL_DEVICE
  #ip route delete default via $LOCAL_IP dev $LOCAL_DEVICE
  #echo "You should now have a new IP"
  #curl https://checkip.amazonaws.com/
elif [ "$ROUTE_SINGLE_IP" -eq 1 ]; then
  if [ -z ${IP_RANGE_BEHIND_VPN+x} ]; then echo "IP_RANGE_BEHIND_VPN must be set"; exit -1; fi
  # https://www.commandlinefu.com/commands/view/1908/get-the-ip-address-of-a-machine.-just-the-ip-no-junk.
  TUNNEL_DEVICE_IP=`ip -o -4 a show dev ppp0 | awk -F '[ /]+' '/global/ {print $4}'`
  ip route add $IP_RANGE_BEHIND_VPN via $TUNNEL_DEVICE_IP dev $LOCAL_DEVICE
fi