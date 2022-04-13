{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.work;
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

  # TODO: How the F do I do a derivation in here for internal binaries?
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      google-cloud-sdk
      pulumi-bin
    ];
  };
}
