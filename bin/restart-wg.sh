#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Because wireguard on macos is.... stupider than jupiter when things migrate. Kick it in the ass manually if needed.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

for action in unload load; do
  sudo launchctl ${action} /Library/LaunchDaemons/org.nixos.wireguard-utun99.plist
done
