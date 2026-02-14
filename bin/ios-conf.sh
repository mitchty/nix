#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: For ios devices generates a conf file for the wireguard app that
# I can use that qrencode thingy to dump out a qr ascii code to use to load into
# the beast
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

cd "${_dir}/.." || exit 126

host="${1?need a hostname to add bra}"
shift
ipaddr="${1?need the wireguard ip as well to add bra}"

dest="crypt/wireguard/${host}"
install -dm700 crypt crypt/wireguard "${dest}"

conf="${dest}/mobile.conf"

cat << FIN | tee "${conf}"
[Interface]
PrivateKey = $(cat ${dest}/privatekey)
Address = ${ipaddr}/24
DNS = 10.10.10.1

[Peer]
PublicKey = $(cat crypt/wireguard/gw0/publickey)
#AllowedIPs = 0.0.0.0/0
AllowedIps = 10.10.10.0/24, 192.168.255.0/24
Endpoint = home.mitchty.net:51820
FIN

qrencode -t ansiutf8 < "${conf}"
