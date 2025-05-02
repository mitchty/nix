#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# Description: Macos nix bootstrap script to get nix+nix-darwin installed so
# that we can setup a new macos install.
#
# Here to do all the prerequisites like create a case sensitive ~/src dir.
#
# Should be idempotent (HINT FUTURE MITCH DON'T BREAK IT DUMASS)
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

# Stage 1: setup a case sensitive ~/src to store source code like normal.

# Get the internal apfs disk
#apfsdisk=$(diskutil list internal virtual | awk '/APFS Container Scheme/' | sed -e 's|.*\(disk[0-9]\)$|\1|g')

apfsdisk=$(/usr/bin/stat -f "%Sd" / | sed -e 's|s[0-9]||g')
dest="/Users/${USER}/src"
name=$(echo "${dest}" | tr '/' '_' | sed -e 's|^_||g')

info() {
  printf "info: %s\n" "$*" >&2
}

cmd() {
  printf "cmd: %s\n" "$*" >&2
  sudo "$@"
}

if ! diskutil list | grep -q "${name}"; then
  install -dm755 "${dest}"
  cmd sudo diskutil apfs addVolume "${apfsdisk}" "Case-sensitive APFS" "${name}" -mountpoint "${dest}"
else
  info "${dest} already present"
fi

#diskutil apfs addVolume "${apfsdisk}" 'Case-sensitive APFS' "${name}" -mountpoint ${dest}
#printf "It looks like %s is the internal apfs disk\n" "${apfsdisk}" >&2

# Use the determinate nix installer for macos
if ! command -v nix 2>&1; then
  info no nix
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
else
  info nix already installed
fi

printf "All set copy crap into ~/src and update config to add:\n"
echo nix run nix-darwin --experimental-feature nix-command --experimental-feature flakes -- switch --flake ~/src/pub/github.com/mitchty/nix
