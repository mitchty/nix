#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# Description: Macos nix bootstrap script to get nix+nix-darwin installed so
# that we can setup a new macos install.
#
# Here to do all the prerequisites like create a case sensitive ~/src dir and
# run the base nix installer to bootstrap into nix-darwin.
#
# Should be idempotent (HINT FUTURE MITCH DON'T BREAK IT DUMASS)
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

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

  voluuid=$(diskutil info "${name}" | awk '/Volume UUID/ {print $3}')

  if [ ! -f /etc/fstab ]; then
    echo install -m644 /dev/null /etc/fstab
  fi

  # Don't have spotlight index stuff in here it gets weird. Besides I got ripgrep for that stuff.
  touch "${dest}"/.metadata_never_index

  # This is bsd sed bear in mind for the -i '' bit
  sed -i '' -e "|${dest}|d" /etc/fstab
  printf "UUID=%s %s apfs rw,auto 0 0" "${voluuid}" "${dest}" | tee -a /etc/fstab
else
  info "${dest} already present"
fi

#diskutil apfs addVolume "${apfsdisk}" 'Case-sensitive APFS' "${name}" -mountpoint ${dest}
#printf "It looks like %s is the internal apfs disk\n" "${apfsdisk}" >&2

# Use the determinate nix installer for macos, just don't install the determinate nix itself aka no/yes
if ! command -v nix 2>&1; then
  info no nix
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
else
  info nix already installed
fi

# TODO: for bootstrapping, I should setup a bootstrap target for darwin that this runs against.
#
# This task is for future me when I rebuild the old x86 laptop.
printf "All set copy crap into ~/src and update config to add this host then:\n"
echo sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
echo nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch --flake ".#${HOST}"
