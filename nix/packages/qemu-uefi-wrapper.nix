{
  stdenv,
  lib,
  pkgs,
  makeWrapper,
  system,
}:
# TODO: This is bogus but whatever, hacks for now future me can fix it when I
# figure out how to constrain these package derivations just on one platform but do it outside of the
if (system == "x86_64-linux") then
  stdenv.mkDerivation {
    pname = "qemu-uefi-wrapper";
    version = "0.1.0"; # version is bs

    # This is not complicated/complect I'm just a lazy ass
    src = pkgs.writeText "qemu-system-x86_64-uefi" ''
      qemu-system-x86_64 -bios ${pkgs.OVMF.fd}/FV/OVMF.fd "$@"
    '';

    # Need this or the make derivation function will try to unpack ^^^
    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out/bin
      install -m 755 $src $out/bin/qemu-system-x86_64-uefi
    '';

    meta = {
      mainProgram = "qemu-system-x86_64-uefi";
      description = "qemu uefi wrapper to make testing easier and forget stupid cli args to quemu as well as where the hell the OVMF firmware is";
      maintainers = with lib.maintainers; [ mitchty ];
    };
  }
else
  stdenv.mkDerivation {
    pname = "qemu-uefi-wrapper";
    version = "0.0.0";
    src = ./.;
    installPhase = "mkdir -p $out/bin";
  }
