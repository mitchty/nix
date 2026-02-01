{
  stdenv,
  lib,
  pkgs,
}:

let
  mkStatic =
    cross:
    cross.btop.overrideAttrs (old: {
      pname = "btop-static";

      # force static
      NIX_CFLAGS_LINK = "-static";
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [
        "-DBUILD_SHARED_LIBS=OFF"
        "-DCMAKE_EXE_LINKER_FLAGS=-static"
      ];

      buildInputs = with cross; [
        ncurses
        libuv
        hwloc
        zlib
      ];

      dontStrip = true;
    });
in
{
  # native static musl (x86_64)
  btop-static-x86_64 = mkStatic pkgs.pkgsCross.musl64;

  # cross static musl (aarch64)
  btop-static-aarch64 = mkStatic pkgs.pkgsCross.aarch64-multiplatform-musl;
}
