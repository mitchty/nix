#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# Description: Check for updates to firmware for crap I own, none of this shell
# is pretty, just functional enough to get the job done.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eu}"

ok=0

TEMP=${TMPDIR:-/tmp}
T="${TEMP}/${_base}-$$"

install -dm755 "${T}"

cleanup() {
  [ -d "${T}" ] && rm -fr "${T}"
  [ ${ok} -ne 0 ] && printf "note: %s did not run succesfully try again with SETOPTS=-eux \n" "${_base}" >&2
  exit $ok
}

trap cleanup EXIT

fw() {
  v=${1?need a version bra}
  printf "https://tascam.com/downloads/products/tascam/mixcast_4/mixcast4_fw_%s.zip" "${v}"
}

cd "${T}"

puppeteer print --no-sandbox https://tascam.com/us/product/mixcast_4/download mixcast4.pdf > /dev/null 2>&1

curr="$(fw v131)"

pdftotext mixcast4.pdf mixcast4.txt

found=$(cat mixcast4.txt | grep -E 'Firmware V' | sort -ur | head -n1 | awk '{print $2}' | tr V v | tr -d \.)

latest=$(fw ${found})

if [ "${curr}" != "${latest}" ]; then
  ok=$((ok + 1))
  old=$(echo "${curr}" | awk -F\_v '{print $2}' | tr -d '.zip')
  new=$(echo "${latest}" | awk -F\_v '{print $2}' | tr -d '.zip')
  printf "mixcast4 firmware skew current=%s found=%s\n" "${old}" "${new}"
  printf "change curr to: %s\n" "${latest}"
else
  printf "mixcast4 version %s already latest nothing to do \n" "${found}"
fi

# And the GW7664 firmware too cause for some crazy reason there is NO non
# versioned url for the thing. My biggest gripe about the grandstream ap tbh.
# How the heck am I supposed to know its updated ungh.
fw() {
  v=${1?need a version bra}
  w=$(echo "${v}" | tr '.' '_')
  printf "firmware.grandstream.com/gwnap/%s" "${w}"
}

puppeteer print --no-sandbox https://www.grandstream.com/support/firmware gwnap.pdf > /dev/null 2>&1

have="1.0.25.38"
curr="$(fw ${have})"

pdftotext gwnap.pdf gwnap.txt

found=$(cat gwnap.txt | grep -A2 -E 'GWN7664$' | tail -n1)

latest=$(fw ${found})

if [ "${curr}" != "${latest}" ]; then
  ok=$((ok + 1))
  old=${have}
  new=${found}
  printf "GWN7664 firmware skew current=%s found=%s\n" "${old}" "${new}"
  printf "change curr to: %s\n" "${latest}"
else
  printf "GWN7664 version %s already latest nothing to do \n" "${found}"
fi
