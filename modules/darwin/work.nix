{ inputs, config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.work;
  fakesha = lib.fakeSha256;
  uri = "https://artifactory.algol60.net/artifactory/vshasta-support-generic-local/stable";

  # Nix version for vshasta/craypc is bogus, just picking the YYYY.mm.DD this
  # derivation was last updated.
  datever = "2022.06.02";

  # Note: both these derivations depend on vpn to work might be an issue for
  # future me with build offloading at some point. Sorry future me.
  vshasta = pkgs.stdenv.mkDerivation rec {
    name = "vshasta-${version}";
    version = datever;

    src = pkgs.fetchurl {
      url = "${uri}/vshasta/darwin-amd64/vshasta";
      sha256 = "sha256-DsWwsHq92a7tkPhq+DRyqO3MqtjLbl8ha1FopWHPQFU=";
    };

    # We don't need to do anything but install from src ^^
    phases = [ "installPhase" ];

    installPhase = ''
      install -m755 -D $src $out/bin/vshasta
    '';
  };
  craypc = pkgs.stdenv.mkDerivation rec {
    name = "craypc-${version}";
    version = datever;

    src = pkgs.fetchurl {
      url = "${uri}/craypc/latest/macos-amd64/craypc";
      sha256 = "sha256-egOemDFw16H+S1mzCeMEK33FQDvzWCvVIDXYwHw7rU8=";
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
      google-cloud-sdk
      yq-go
    ] ++ [
      inputs.mitchty.packages.${pkgs.system}.jira-cli
      craypc
      vshasta
    ];
  };
}
