{
  stdenv,
  lib,
  pkgs,
}:
# mostly just abuse this derivation to run btop on my synology frankenlinux
# whatever flavor of linux it is.
pkgs.pkgsCross.musl64.btop.overrideAttrs (old: {
  pname = "btop-static-x86_64";

  NIX_CFLAGS_LINK = "-static";
  cmakeFlags = (old.cmakeFlags or [ ]) ++ [
    "-DBUILD_SHARED_LIBS=OFF"
    "-DCMAKE_EXE_LINKER_FLAGS=-static"
  ];

  buildInputs = with pkgs.pkgsCross.musl64; [
    ncurses
    libuv
    hwloc
    zlib
  ];

  dontStrip = true;
})
