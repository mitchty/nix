#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# Description: Unified versions script to handle listing latest versions,
# firmware, and updating of versions.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eu}"

ok=0

TEMP=${TMPDIR:-/tmp}
T="${TEMP}/${_base}-$$"

install -dm755 "${T}"

cleanup() {
  # no it isn't unreachable its a runtime witness ungh
  #shellcheck disable=SC2317
  [ -d "${T}" ] && rm -fr "${T}"
  #shellcheck disable=SC2317,SC2086
  [ ${ok} -ne 0 ] && printf "note: %s did not run succesfully try again with SETOPTS=-eux \n" "${_base}" >&2
  exit $ok
}

trap cleanup EXIT TERM INT QUIT

uname_s=$(uname -s)
uname_m=$(uname -m)

# Stupid simple function to match nix lib platform double... roughly at least
# for my needs in using jq to get at package derivations from nix eval type
# stuff.
double() {
  if [ "${uname_s}" = "Linux" ]; then
    arch="${uname_m}-linux"
  elif [ "${uname_s}" = "Darwin" ]; then
    # nix platform arch is named aarch64 not arm64 like uname returns on macos
    if [ "${uname_m}" = "arm64" ]; then
      arch="aarch64-darwin"
    else
      arch="${uname_m}-darwin"
    fi
  fi
  echo "${arch}"
}

# Version comparison function
cmp_versions() {
  latest=$1
  shift
  ours=$1

  if [ "${latest}" != "${ours}" ]; then
    printf "%s latest version out of date: ours=%s latest=%s\n" "${pkg}" "${ours}" "${latest}" >&2
    printf "nix-update --flake %s --version %s\n" "${pkg}" "${latest}"
    ok=$((ok + 1))
  else
    if [ "${VERBOSE:-}" != "" ]; then
      printf "%s have=%s latest=%s\n" "${pkg}" "${ours}" "${latest}" >&2
    fi
  fi
}

update() {
  # TODO: for now just look for certain things, future me figure out how to nix
  # eval what packages are present in the flake.

  ${DIR:+cd $DIR}

  # Check that there are no uncommitted changes exit if any uncommitted
  # changes present. Note rando files not applicable, only changes to
  # tracked stuff.
  #
  # Abusing git commit -u to be sure any changes/updates only apply to
  # the specific package nix-update updated.
  if ! git diff-index --quiet HEAD; then
    printf "local git changes, refusing to continue.\n" >&2
    exit 2
  fi

  arch=$(double)

  # 2> /dev/null to nuke the stderr warning: messages
  for pkg in $(pkgs); do
    if nix eval --raw ".#${pkg}.latest" 2> /dev/null; then
      evalstring=$(nix eval --raw ".#${pkg}.latest" 2> /dev/null)

      # Doing it this way so I don't have to rerun things, so go away
      #shellcheck disable=SC2181
      if [ "$?" -eq 0 ]; then
        latest=$(eval "${evalstring}")
        ours=$(nix eval --raw ".#${pkg}.version" 2> /dev/null)

        if [ "${latest}" != "${ours}" ]; then
          printf "%s latest version out of date: ours=%s latest=%s\n" "${pkg}" "${ours}" "${latest}" >&2
          printf "nix-update --flake %s --version %s\n" "${pkg}" "${latest}"
          nix-update --flake "${pkg}" --version "${latest}"
          nix build ".#${pkg}"
          git add -u
          git commit -n -m "${pkg} ${latest}"
        fi
      fi
    fi
  done
}

pkgs() {
  arch=$(double)
  nix flake show --json 2> /dev/null | jq -r ".packages.\"${arch}\" | keys[]"
  #   nix flake show --json | jq -r ".packages.\"${arch}\" | keys[]"
}

latest() {
  cd $_dir || exit 126
  arch=$(double)
  # 2> /dev/null to nuke the stderr warning: messages
  for pkg in $(pkgs); do
    if nix eval --raw ".#${pkg}.latest" > /dev/null 2>&1; then
      evalstring=$(nix eval --raw '.#'${pkg}'.latest' 2> /dev/null)
      # Doing it this way so I don't have to rerun things, so go away
      #shellcheck disable=SC2181
      if [ "$?" -eq 0 ]; then
        latest=$(eval ${evalstring})
        ours=$(nix eval --raw ".#${pkg}.version" 2> /dev/null)

        if [ "$?" -eq 0 ]; then
          cmp_versions "${latest}" "${ours}"
        fi
      fi
    fi
  done

  # Ok this is for overlays, and I'm not sure I want to trawl the entire set so
  # just specifying things manually for now. If i start overlaying a lot more
  # future me problem.
  #for pkg in $(nix eval ".#legacyPackages.\"${arch}\"" --apply builtins.attrNames --json 2> /dev/null | jq -r '.[]'); do
  for pkg in yt-dlp bgutil-ytdlp-pot-provider yt-dlp-get-pot; do
    if nix eval --raw ".#.legacyPackages.\"${arch}\".${pkg}.latest" > /dev/null 2>&1; then
      evalstring=$(nix eval --raw ".#.legacyPackages.\"${arch}\".${pkg}.latest" 2> /dev/null)
      # Doing it this way so I don't have to rerun things, so go away
      #shellcheck disable=SC2181
      if [ "$?" -eq 0 ]; then
        latest=$(eval ${evalstring})
        ours=$(nix eval --raw ".#.legacyPackages.\"${arch}\".${pkg}.version" 2> /dev/null)

        if [ "$?" -eq 0 ]; then
          cmp_versions "${latest}" "${ours}"
        fi
      fi
    fi
  done
}

fw() {
  v=${1?need a version bra}
  printf "https://tascam.com/downloads/products/tascam/mixcast_4/mixcast4_fw_%s.zip" "${v}"
}

# Check for latest firmware so I can know when new crap is released for things
# that need manual intervention.
firmware() {
  # puppeteer only runs on linux
  [ "${uname_s}" != "Linux" ] && return 0

  cd "${T}" || exit 126

  puppeteer print --no-sandbox https://tascam.com/us/product/mixcast_4/download mixcast4.pdf > /dev/null 2>&1

  curr="$(fw v131)"

  pdftotext mixcast4.pdf mixcast4.txt

  # idgaf about this
  #shellcheck disable=SC2002
  found=$(cat mixcast4.txt | grep -E 'Firmware V' | sort -ur | head -n1 | awk '{print $2}' | tr V v | tr -d \.)

  latest=$(fw "${found}")

  # whining about the \_ being _, duh thats the point
  #shellcheck disable=SC1001
  old=$(echo "${curr}" | awk -F\_v '{print $2}' | tr -d '.zip')
  #shellcheck disable=SC1001
  new=$(echo "${latest}" | awk -F\_v '{print $2}' | tr -d '.zip')

  if [ "${curr}" != "${latest}" ]; then
    ok=$((ok + 1))
    printf "mixcast4 firmware skew current=%s have=%s\n" "${old}" "${new}"
    printf "change curr to: %s\n" "${latest}"
  else
    if [ "${VERBOSE:-}" != "" ]; then
      printf "mixcast4 firmware latest current=%s have=%s\n" "${old}" "${new}"
    fi
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

  have="1.0.25.41"
  curr="$(fw ${have})"

  pdftotext gwnap.pdf gwnap.txt

  cp gwnap.txt /tmp/gwnap.debug

  # idgaf about this
  #shellcheck disable=SC2002
  found=$(cat gwnap.txt | grep -A10 -E 'GWN7664$' | grep -E '[0-9]+.[0-9]+.[0-9]+.[0-9]+' | head -n1)

  #  latest=$(fw "${found}")
  latest=${found}

  old=${have}
  new=${found}

  if [ "${old}" != "${new}" ]; then
    ok=$((ok + 1))
    printf "GWN7664 firmware skew current=%s have=%s\n" "${old}" "${new}"
    printf "change curr to: %s\n" "${latest}"
  else
    if [ "${VERBOSE:-}" != "" ]; then
      printf "GWN7664 firmware latest current=%s have=%s\n" "${old}" "${new}"
    fi
  fi
}

help() {
  printf "fatal: run me with either no args for default list behavior or update to update versions of flake packages\n" >&2
  ok=42
}

# Arg handling here is stupid simple.
action="${1:-default}"
case "${action}" in
  default)
    firmware
    latest
    ;;
  latest)
    latest
    ;;
  firmware)
    firmware
    ;;
  update)
    update
    ;;
  # I constantly use the wrong word so make both do the same thing cause lazy
  upgrade)
    update
    ;;
  pkgs)
    pkgs
    ;;
  help)
    help
    ;;
  *)
    help
    ;;
esac
