#!/usr/bin/env zsh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Hack workaround until I can debug why emacs seq package seems to
# cause an emacs process to spin at 100% cpu on macos only, killing it works
# though so...
#
# zsh so I can abuse =() and not care about tempfiles for a quick one off script
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

pgrep -lif emacs

# abuse grep for a set completement so we don't kill $USER emacs pid(s), just
# the nix build user stuff
for pid in $(grep -vxF -f =(pgrep -U $(id -u)) =(pgrep emacs)); do
    ps -ef | grep ${pid} | grep -v grep # not great but eh
    printf "kill -TERM %s?" "${pid}" >&2
    read
    sudo kill -TERM ${pid}
done

# TODO: For future me to debug:
# $ ./src/wtf.zsh
# 13880 /nix/store/yn1i1ni75diqf6iha5fidp3gpxx36b8j-emacs29/bin/emacs
# 30161 xargs -0 -I {} -n 1 -P 16 sh -c emacs --batch --eval '(setq large-file-warning-threshold nil)' -f batch-native-compile {} || true
# 30167 sh -c emacs --batch --eval '(setq large-file-warning-threshold nil)' -f batch-native-compile /nix/store/n38k8swjzbpaixpvcqav2gh962i54cyw-emacs-seq-2.23/share/emacs/site-lisp/elpa/seq-2.23/tests/seq-tests.el || true
# 30181 emacs --batch --eval (setq large-file-warning-threshold nil) -f batch-native-compile /nix/store/n38k8swjzbpaixpvcqav2gh962i54cyw-emacs-seq-2.23/share/emacs/site-lisp/elpa/seq-2.23/tests/seq-tests.el
#   320 30181 30167   0  9:19AM ??         0:00.00 (emacs-29.0.60)

# Its that 30181 process that needs killing for some reason, and it is *fine* to
# do but why I've no idea yet, no time to investigate. Killing that one
# fixes/allows the build to proceed.
