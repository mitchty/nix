{ inputs, config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.work;
  fake = lib.fakeSha256;

  snyk = pkgs.stdenv.mkDerivation rec {
    name = "snyk-${version}";
    version = "1.988.0";

    src = pkgs.fetchurl {
      url = "https://static.snyk.io/cli/v${version}/snyk-macos";
      sha256 = "sha256-pxdBLlyVFjD0lAlLFzpMkBf4n6vq8WqAM0vmOYQ7i5E=";
    };

    # We don't need to do anything but install the binary
    phases = [ "installPhase" ];

    installPhase = ''
      install -m755 -D $src $out/bin/snyk
    '';
  };

  terragrunt_0324 = pkgs.stdenv.mkDerivation rec {
    name = "terragrunt-${version}";
    version = "0.32.4";

    src = pkgs.fetchurl {
      url = "https://github.com/gruntwork-io/terragrunt/releases/download/v${version}/terragrunt_darwin_amd64";
      sha256 = "sha256-+DRsS6U7agtU+RAmBCi6yL4k8tFEuI8KDEP0JwrR+5I=";
    };

    # We don't need to do anything but install from src ^^
    phases = [ "installPhase" ];

    installPhase = ''
      install -m755 -D $src $out/bin/terragrunt
    '';
  };

  # TODO: For work see if newer stuff works later, for now use the blessed
  # version.
  #
  # Just using overrideAttrs doesn't work like you'd think ref:
  # https://github.com/NixOS/nixpkgs/issues/86349
  #
  # Go modules are ass.
  #
  # terragrunt_0324 = pkgs.terragrunt.overrideAttrs (old: rec {
  #   pname = "terragrunt";
  #   version = "0.32.4";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "gruntwork-io";
  #     repo = pname;
  #     rev = "refs/tags/v${version}";
  #     sha256 = "sha256-bqJlUjnyV3lNO9wHlK9uEHC6TsuQ3HIPzLaZu8sCj9Q=";
  #   };
  #   vendorHash = pkgs.lib.fakeSha256;
  # });
  # This no work either future me figure out how to override go module builds, this is lame af.
  # terragrunt_0324 =
  #   let
  #     pname = "terragrunt";
  #     version = "0.32.4";
  #     src = pkgs.fetchFromGitHub {
  #       owner = "gruntwork-io";
  #       repo = pname;
  #       rev = "refs/tags/v${version}";
  #       sha256 = "sha256-bqJlUjnyV3lNO9wHlK9uEHC6TsuQ3HIPzLaZu8sCj9Q=";
  #     };
  #   in
  #   (inputs.terragrunt-old.legacyPackages.${pkgs.system}.terragrunt.override {
  #     buildGoModule = args: pkgs.buildGoModule (args // {
  #       vendorSha256 = "sha256-y84EFmoJS4SeA5YFIVFU0iWa5NnjU5yvOj7OFE+jGN0=";
  #       inherit src version;
  #     });
  #   });
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
      colima
      dive
      docker
      docker-credential-helpers
      docker-distribution
      google-cloud-sdk
      k9s
      kubectl
      kubectl-convert
      kubent
      (pkgs.wrapHelm pkgs.kubernetes-helm {
        plugins = [
          inputs.mitchty.packages.${pkgs.system}.helm-unittest
        ];
      })
      kubernetes-helm
      kubespy
      lima
      pluto
      qemu
      yq-go
    ] ++ [
      coreutils
      mkdocs
      terragrunt_0324
      inputs.mitchty.packages.${pkgs.system}.jira-cli
      inputs.terraform-old.legacyPackages.${pkgs.system}.terraform
      pandoc
      skopeo
      snyk
      xlsx2csv
    ];
  };
}
