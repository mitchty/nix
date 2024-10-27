#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Update flake inputs, outside the flake for now until I
# finish migrating off of my hacky af setup.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eu}"

# Note this whole thing should be swapped to something like this later
# in some flake package in a persystem like call
update="nix flake lock"
for input in mitchty nixpkgs nixpkgs-darwin emacs-overlay home-manager darwin dnsblacklist unstable; do
  update="${update} --update-input ${input}"
done

echo ${update}
${update}

# TODOfuture mitch fix it past mitch is as is tradition a jerk
# # nix run .#update to update just the flake inputs that need updating often.
# #
# # Most of the inputs are fine to keep pinned older as they
# # don't need to be updated as often like say nil or deploy-rs
#
# Yoinked idea from https://github.com/srid/nixos-flake/blob/7b19503e7f8c7cc0884fc2fbd669c0cc2e05aef5/flake-module.nix#L38
# updatepkg = writeShellApplication: foldl':
#   let
#     inputs = [
#       "mitchty"
#       "nixpkgs"
#       "emacs-overlay"
#       "home-manager"
#       "darwin"
#       "nixpkgs-darwin"
#     ];
#   in
#   writeShellApplication {
#     name = "update-flake-inputs";
#     text = ''
#       nix flake lock ${foldl' (acc: x: acc + " --update-input " + x) "" inputs}
#     '';
#   };
