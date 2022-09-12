#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash coreutils curl jq htmlq
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Check for out of date stuff in my nix setup
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

ok=0

stats_cur="v2.7.34"
stats_found="$(curl --silent 'https://api.github.com/repos/exelban/stats/releases/latest' | jq -r '.tag_name')"

if [ "${stats_cur}" != "${stats_found}" ]; then
  printf "stats out of date have %s latest is %s\n" "${stats_cur}" "${stats_found}" >&2
  ok=$(( ok + 1 ))
fi

swiftbar_cur="v1.4.3"
swiftbar_found="$(curl --silent 'https://api.github.com/repos/swiftbar/SwiftBar/releases/latest' | jq -r '.tag_name')"

if [ "${swiftbar_cur}" != "${swiftbar_found}" ]; then
  printf "swiftbar out of date have %s latest is %s\n" "${swiftbar_cur}" "${swiftbar_found}" >&2
  ok=$(( ok + 1 ))
fi

vlc_cur="3.0.17.3"
vlc_found=${vlc_cur}
# VLC seems to have tags that don't actually exist/are built, so we have to
# iterate through the tags to find the true "latest" by trying HEAD on an actual
# url.
for tag in $(curl --silent 'https://api.github.com/repos/videolan/vlc/git/refs/tags' | jq -r '.[].ref' | sed -e 's|refs/tags/||' | grep -Ev '(dev|rc|git|pre|test|svn)' | sort -Vr); do
  if curl --fail -L -I http://get.videolan.org/vlc/${tag}/macosx/vlc-${tag}-intel64.dmg > /dev/null 2>&1; then
    vlc_found="${tag}"
    break;
  else
    printf "note: newer VLC version tag %s found but not present for download\n" "${tag}" >&2
  fi
done

if [ "${vlc_cur}" != "${vlc_found}" ]; then
  printf "vlc out of date have %s latest is %s\n" "${vlc_cur}" "${vlc_found}" >&2
  ok=$(( ok + 1 ))
fi

obs_cur="28.0.1"
obs_found="$(curl --silent 'https://api.github.com/repos/obsproject/obs-studio/releases/latest' | jq -r '.tag_name')"

if [ "${obs_cur}" != "${obs_found}" ]; then
  printf "obs out of date have %s latest is %s\n" "${obs_cur}" "${obs_found}" >&2
  ok=$(( ok + 1 ))
fi

stretchly_cur="v1.11.0"
stretchly_found="$(curl --silent 'https://api.github.com/repos/hovancik/stretchly/releases/latest' | jq -r '.tag_name')"

if [ "${stretchly_cur}" != "${stretchly_found}" ]; then
  printf "stretchly out of date have %s latest is %s\n" "${stretchly_cur}" "${stretchly_found}" >&2
  ok=$(( ok + 1 ))
fi

wireshark_cur="3.6.7"
wireshark_found="$(curl --location --silent https://www.wireshark.org/#download | htmlq -wpt | awk '/current stable/ {print $8}' | sed 's/.$//')"

if [ "${wireshark_cur}" != "${wireshark_found}" ]; then
  printf "wireshark out of date have %s latest is %s\n" "${wireshark_cur}" "${wireshark_found}" >&2
  ok=$(( ok + 1 ))
fi

exit $ok
