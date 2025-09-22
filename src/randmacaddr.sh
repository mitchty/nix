#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# Description: Set a random mac address on an interface, faster than going
# through a reboot cycle and intended to be abused via systemd units
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eu}"

iface="${1?need an interface}"

# Get current wan ip off the given iface
wan_ip() {
  ip -brief address show | awk '/'"${iface}"'/ {sub(/\/[^ ]+$/, "", $3); print $3}'
}

ok=1

until [ "${ok}" -eq 0 ]; do
  set -- $(od -An -N6 -tx1 /dev/urandom)

  # sets locally administered bit (0xFE bitmask) and clears the multicast bit (0x02 bitmask) so its not "truly"
  # random but should be more "correct"
  mac=$(printf '%02x:%02x:%02x:%02x:%02x:%02x\n' \
    $(((0x$1 & 0xFE) | 0x02)) $((0x$2)) $((0x$3)) $((0x$4)) $((0x$5)) $((0x$6)))

  echo ip link set dev ${iface} address "${mac}"
  ip link set dev ${iface} address "${mac}"

  echo systemctl stop dhcpcd.service
  systemctl stop dhcpcd.service

  echo ip addr flush ${iface}
  ip addr flush ${iface}

  echo systemctl start dhcpcd.service
  systemctl start dhcpcd.service

  # comcast seems to set things to 192.168 so if we find that rfc1918 range in the
  # ip, we need to retry getting an ip.
  if wan_ip | grep -qE '192.168'; then
    printf "dhcp got an rfc1918 address" >&2
  else
    ok=0
  fi
done

rm -f /var/tmp/newip

wan_ip > /var/tmp/wanip
