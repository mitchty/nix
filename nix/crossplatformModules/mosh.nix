{
  config,
  lib,
  pkgs,
  options,
  ...
}:

with lib;

let
  name = "mosh";
  cfg = config.services.common.${name};
in
{
  options = {
    services.common.${name} = {
      enable = mkEnableOption "${name} service";

      package = mkOption {
        default = pkgs.${name};
        defaultText = "pkgs.${name}";
        description = "Which derivation to use";
        type = types.package;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (options ? launchd.user.agents) (
      mkIf pkgs.stdenv.hostPlatform.isDarwin {
        # darwin firewall setup? TODO figure it out future mitch if its needed
      }
    ))
    (optionalAttrs (options ? systemd.services) (
      mkIf pkgs.stdenv.hostPlatform.isLinux {
        networking.firewall.allowedUDPPortRanges = [
          {
            from = 60000;
            to = 60010;
          }
        ];
      }
    ))
    # common between darwin/nixos config
    {
      environment.systemPackages = [ cfg.package ];
    }
  ]);
}
