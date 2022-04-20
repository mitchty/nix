{ inputs, config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.work;
  fakesha = lib.fakeSha256;
  uri = "http://car.dev.cray.com/artifactory";

  # Note: both these derivations depend on vpn to work might be an issue for
  # future me with build offloading at some point. Sorry future me.
  vshasta = pkgs.stdenv.mkDerivation
    rec {
      name = "vshasta-${version}";

      # Nix version is bogus, just picking the YYYY.mm.DD this derivation was last
      # updated.
      version = "2022.04.13";

      src = pkgs.fetchurl {
        url = "${uri}/vshasta/cli/latest/darwin-amd64/vshasta";
        sha256 = "sha256-LQPQt4f6Yu54Ep+LS0GZ6dfS2wti5FUk1QREhiTTjsc=";
      };

      # We don't need to do anything but install from src ^^
      phases = [ "installPhase" ];

      installPhase = ''
        install -m755 -D $src $out/bin/vshasta
      '';
    };
  craypc = pkgs.stdenv.mkDerivation
    rec {
      name = "craypc-${version}";

      # Nix version is bogus, just picking the YYYY.mm.DD this derivation was last
      # updated.
      version = "2022.04.13";

      src = pkgs.fetchurl {
        url = "${uri}/internal/craypc/latest/macos-amd64/craypc";
        sha256 = "sha256-7eSzttb1dUbuQeP5CCsgOKbsfELq141z6D9iCBocMN0=";
      };

      # We don't need to do anything but install from src ^^
      phases = [ "installPhase" ];

      installPhase = ''
        install -m755 -D $src $out/bin/craypc
      '';
    };
in
{
  options = {
    services.work = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Work related shenanigans.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # openstackclient we only pull from knowing a working setup due to
      # https://github.com/NixOS/nixpkgs/pull/166297
      inputs.nixpkgs.legacyPackages.${pkgs.system}.openstackclient
      google-cloud-sdk
      craypc
      vshasta
    ];
  };
}
