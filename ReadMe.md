# L2TP ipsec vpn setup scripts

This is a collection of scripts to help setup an **L2TP IPSec client on CentOS 7**. There are a bunch of tutorials out there, but I had a hard time finding a working solutiion. :fire:

If you used [hwdsl2/setup-ipsec-vpn](https://github.com/hwdsl2/setup-ipsec-vpn) for the server, then these scripts should work. :+1:

Tested on `CentOS Linux release 7.5.1804 (Core)`. The client setup is mostly inspired by [Archlinux wiki: Openswan L2TP/IPsec VPN client setup](https://wiki.archlinux.org/index.php/Openswan_L2TP/IPsec_VPN_client_setup) and adapted for CentOS 7

## Getting started

1. Clone the project
2. Make sure scripts are executable
3. Setup your environment variables
4. Execute the setup script
5. Each time you want to connect, run the start script `start_vpn_client.sh` with `sudo`

```bash
git clone https://github.com/GabLeRoux/l2tp-ipsec-vpn-setup-scripts.git
cd l2tp-ipsec-vpn-setup-scripts
cp .env.example .env
vim .env
sudo setup_vpn_client.sh
```

```bash
sudo start_vpn_client.sh
```

## Why Centos?

Please don't ask.

## Is this safe?

Read the scripts, I'm not your mom :wink:. Running things from the internet as `sudo` is never safe friend.

## Is this working?

**Yes**, it does work. Only the part for routing needs some manual actions. Refer to [Archlinux wiki Routing section](https://wiki.archlinux.org/index.php/Openswan_L2TP/IPsec_VPN_client_setup#Routing)

Let's say there is this IP behind the VPN:
`xxx.xxx.xxx.xxx` and you'd like your system to reach it using the `ppp0` device (your vpn tunnel). You first need to get your `ppp0` device `peer` ip:

```bash
ip a show dev ppp0
```
```
5: ppp0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1280 qdisc pfifo_fast state UNKNOWN group default qlen 3
    link/ppp
    inet 192.168.42.10 peer 192.168.42.1/32 scope global ppp0
       valid_lft forever preferred_lft forever
```
In my case, it's `192.168.42.1`. Then you need to update your routing table to let your system know how to reach the desired server behind vpn using your `ppp0` device. Command looks like that:

```bash
ip route add xxx.xxx.xxx.xxx via yyy.yyy.yyy.yyy dev pppX
```

or in my case:

```bash
ip route add xxx.xxx.xxx.xxx via 192.168.42.1 dev ppp0
```

## I'm stuck with 'Errno 22: Invalid argument'

Yup, me too. Worked on a vpn I did setup myself using [hwdsl2/setup-ipsec-vpn](https://github.com/hwdsl2/setup-ipsec-vpn), but I'm trying to connect on a different server which I did not configure and I'm still fighting as I'm stuck here:

```
+ ipsec auto --up L2TP-PSK
002 "L2TP-PSK" #1: initiating Main Mode
003 ERROR: "L2TP-PSK" #1: sendto on lo to ###.###.###.###:500 failed in reply packet for main_outI1. Errno 22: Invalid argument
104 "L2TP-PSK" #1: STATE_MAIN_I1: initiate
010 "L2TP-PSK" #1: STATE_MAIN_I1: retransmission; will wait 0.5 seconds for response
003 ERROR: "L2TP-PSK" #1: sendto on lo to ###.###.###.###:500 failed in EVENT_v1_RETRANSMIT. Errno 22: Invalid argument
010 "L2TP-PSK" #1: STATE_MAIN_I1: retransmission; will wait 1 seconds for response
003 ERROR: "L2TP-PSK" #1: sendto on lo to ###.###.###.###:500 failed in EVENT_v1_RETRANSMIT. Errno 22: Invalid argument
010 "L2TP-PSK" #1: STATE_MAIN_I1: retransmission; will wait 2 seconds for response
003 ERROR: "L2TP-PSK" #1: sendto on lo to ###.###.###.###:500 failed in EVENT_v1_RETRANSMIT. Errno 22: Invalid argument
010 "L2TP-PSK" #1: STATE_MAIN_I1: retransmission; will wait 4 seconds for response
003 ERROR: "L2TP-PSK" #1: sendto on lo to ###.###.###.###:500 failed in EVENT_v1_RETRANSMIT. Errno 22: Invalid argument
010 "L2TP-PSK" #1: STATE_MAIN_I1: retransmission; will wait 8 seconds for response
003 ERROR: "L2TP-PSK" #1: sendto on lo to ###.###.###.###:500 failed in EVENT_v1_RETRANSMIT. Errno 22: Invalid argument
010 "L2TP-PSK" #1: STATE_MAIN_I1: retransmission; will wait 16 seconds for response
003 ERROR: "L2TP-PSK" #1: sendto on lo to ###.###.###.###:500 failed in EVENT_v1_RETRANSMIT. Errno 22: Invalid argument
```

Note: I obfuscated VPN Server IP to `###.###.###.###`. If you know how to solve this, please poke me.

## Vagrant

Yeah I prefer Docker, but I had to setup something on an actual machine and docker has no such thing as `systemctl`. Here's how you can try this on vagrant:

```bash
cp .env.example .env
vim .env
vagrant up
vagrant ssh
sudo /app/setup_vpn_client.sh
```

## What's my local ip?

```bash
ip a
```

It should be somewhere in here, look for `eth0` or `wlan0` if you're on a wifi.

## Contributing

Contribution are welcome, I may not maintain this project much, but you can open issues or send pull-requests. :v:

## License

[MIT](LICENSE.md) © [Gabriel Le Breton](https://gableroux.com)
