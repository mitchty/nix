#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash git patch
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Tool to do nix flake init... cargo init... git init.. all at once
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

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

echo 'use flake' > .envrc

git add -A
git commit -m "nix flake init -t github:ipetkov/crane"

# Mostly here until/if/when https://github.com/ipetkov/crane/issues/156 is resolved
cat << 'EOF' | patch -p1
diff --git a/flake.nix b/flake.nix
index 0657077..c5c1c70 100644
--- a/flake.nix
+++ b/flake.nix
@@ -24,21 +24,25 @@
           inherit system;
         };

-        inherit (pkgs) lib;
+        inherit (pkgs) lib stdenv;

         craneLib = crane.lib.${system};
         src = craneLib.cleanCargoSource ./.;

+        # If one needs to customize the build environment here is where to add
+        # to it, mostly only needed for macos
+        buildInputs = [] ++ lib.optionals stdenv.isDarwin [ pkgs.libiconv ];
+
         # Build *just* the cargo dependencies, so we can reuse
         # all of that work (e.g. via cachix) when running in CI
         cargoArtifacts = craneLib.buildDepsOnly {
-          inherit src;
+          inherit src buildInputs;
         };

         # Build the actual crate itself, reusing the dependency
         # artifacts from above.
         my-crate = craneLib.buildPackage {
-          inherit cargoArtifacts src;
+          inherit cargoArtifacts src buildInputs;
         };
       in
       {
@@ -53,7 +57,7 @@
           # we can block the CI if there are issues here, but not
           # prevent downstream consumers from building our crate by itself.
           my-crate-clippy = craneLib.cargoClippy {
-            inherit cargoArtifacts src;
+            inherit cargoArtifacts src buildInputs;
             cargoClippyExtraArgs = "--all-targets -- --deny warnings";
           };

@@ -75,7 +79,7 @@
           # Consider setting $(doCheck = false) on $(my-crate) if you do not want
           # the tests to run twice
           my-crate-nextest = craneLib.cargoNextest {
-            inherit cargoArtifacts src;
+            inherit cargoArtifacts src buildInputs;
             partitions = 1;
             partitionType = "count";
           };
@@ -100,7 +104,7 @@
           nativeBuildInputs = with pkgs; [
             cargo
             rustc
-          ];
+          ] ++ buildInputs;
         };
       });
 }
EOF

rm flake.nix.orig
git add -u
git commit -m "Patch in fix for https://github.com/ipetkov/crane/issues/156"
