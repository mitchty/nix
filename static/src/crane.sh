#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash git patch
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Tool to do nix flake init... cargo init... git init.. all at once
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eux}"

# Arg is the directory to do stuff to, required
dir=${1?}

if [ -e "${dir}" ]; then
  printf "fatal: %S exists, refusing to add stuff to it\n" "${dir}" >&2
  exit 1
fi

install -dm755 "${dir}"

cd "${dir}" || exit 126

nix flake init -t github:ipetkov/crane
git init

echo result > .gitignore

git add -A
git commit -m "nix flake init -t github:ipetkov/crane"

# Mostly here until/if/when https://github.com/ipetkov/crane/issues/156 is resolved
cat << EOF | patch -p1
diff --git a/flake.nix b/flake.nix
index 0657077..04758ea 100644
--- a/flake.nix
+++ b/flake.nix
@@ -24,7 +24,7 @@
           inherit system;
         };

-        inherit (pkgs) lib;
+        inherit (pkgs) lib stdenv;

         craneLib = crane.lib.${system};
         src = craneLib.cleanCargoSource ./.;
@@ -32,12 +32,14 @@
         # Build *just* the cargo dependencies, so we can reuse
         # all of that work (e.g. via cachix) when running in CI
         cargoArtifacts = craneLib.buildDepsOnly {
+          buildInputs = [] ++ lib.optionals stdenv.isDarwin [ pkgs.libiconv ];
           inherit src;
         };

         # Build the actual crate itself, reusing the dependency
         # artifacts from above.
         my-crate = craneLib.buildPackage {
+          buildInputs = [] ++ lib.optionals stdenv.isDarwin [ pkgs.libiconv ];
           inherit cargoArtifacts src;
         };
       in
@@ -100,7 +102,7 @@
           nativeBuildInputs = with pkgs; [
             cargo
             rustc
-          ];
+          ] ++ (optionals stdenv.isDarwin [ libiconv ]);
         };
       });
 }

EOF

rm flake.nix.orig
git add -u
git commit -m "Patch in fix for https://github.com/ipetkov/crane/issues/156"
