#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description:
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--e}"

. $HOME/src/pub/github.com/mitchty/nix/src/lib.sh

# Mostly to make it easy to jumpstart a rust project nix+cargo+git all in one
# via the crane flake.
# Arg is the directory to do stuff to, required
_crane_dir="${1?}"
shift > /dev/null 2>&1 || :
_crane_name="${1}"

if [ -e "${_crane_dir}" ]; then
  printf "fatal: %s already exists, refusing to use it for anything\n" "${_crane_dir}" >&2
  return 1
fi

install -dm755 "${_crane_dir}"

cd "${_crane_dir}" || return 126

template="${CRANE_TEMPLATE:+#}${CRANE_TEMPLATE:-}"
nix flake init -t github:ipetkov/crane"${template}"
git init

# Ignore the result link to /nix/store, it'll never be worth storing
cat << 'FIN' > .gitignore
result
FIN

# Go away I know; this is intentional, makes it easier to just use the
# binaries created directly.
#shellcheck disable=SC2016
cat << 'FIN' > .envrc
# If stdin exists we kinda have to be a login shell
if [ -t 0 ]; then
  export CARGO_TARGET_DIR=$(uniq_cache rust)
else
  export CARGO_TARGET_DIR=$(uniq_cache rust-analyzer)
fi
export PREFIX=${CARGO_TARGET_DIR}

export PATH=$PATH:$(pwd)/bin:$(pwd)/result/bin:${PREFIX}/debug:${PREFIX}/release

# TODO: For unit tests/cargo tests this is.... too much off for now
#export RUST_BACKTRACE=full

# Keep cb from building nix derivations for now
export NONIX=sure

has nix && use flake

[ -e local.env ] && . local.env

# Watch this file and reload direnv on changes, .envrc requires me to reload
# anyway so yeah... (note I could make it automagic but prefer not to)
watch_file flake.nix
FIN

# Setup dev/release profiles to be more to my liking
cat << 'FIN' >> Cargo.toml

# Make dev profile fast but chonky boi files opt-level 0 is *slightly* faster,
# barely but its also murder on cpu caches.
#
# Given dev is more for rapid iteration with an eye on not being ass, give it
# minimal optimization.
[profile.dev]
opt-level = "z"

[profile.dev.build-override]
opt-level = "z"

[profile.dev.package."*"]
opt-level = "z"

# All this is great just slow af so turn on when needed.
[profile.release]
codegen-units = 1
lto = "fat"
opt-level = "z"

[profile.release.build-override]
codegen-units = 1
opt-level = "z"
strip = "debuginfo"

[profile.release.package."*"]
codegen-units = 1
opt-level = "z"
strip = "debuginfo"
FIN

# Add up to this point for debugging in case something fails in a bit
git add -A

# This is my own doing so if I shouldn't allow it thats on me
direnv allow

# Rename it if we want a different name for the thing
if [ -n "${_crane_name}" ]; then
  sed_inplace -e "s/quick-start/${_crane_name}/g" -e "s/cross-musl/${_crane_name}/g" -e "s/my-crate/${_crane_name}/g" Cargo.toml flake.nix
fi

# Set the license to blue oak by default for my crap
sed_inplace -e "s/MIT/Blue Oak Model License 1.0.0/g" Cargo.toml

# Run cargo from nixpkgs to update package repo data
nix run nixpkgs#cargo -- update

# Get the basic build cached straight away in /nix/store and to be sure it builds
nix build -L

# Now we're gtg
git add -A
git commit -m "nix flake init -t github:ipetkov/crane${template}"
