{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.age;
in
{
  options.services.mitchty.age = {
    enable = mkEnableOption "Enable age secrets for home-manager";

    user = mkOption {
      type = types.str;
      default = "mitch";
      description = "User to create SSH identity for, for now this is just for me to sync atuin shell history";
    };

    identityFile = mkOption {
      type = types.str;
      default = "secrets/ssh/id_ed25519-home-manager";
      description = "Path to the age private ssh identity file to use for home-manager agenix";
    };

    identityFilePub = mkOption {
      type = types.str;
      default = "secrets/ssh/id_ed25519-home-manager.pub";
      description = "Path to the age public ssh identity file to use for home-manager agenix";
    };

    linkDest = mkOption {
      type = types.str;
      default = ".ssh/id_ed25519-home-manager";
      description = "Path where to symlink the decrypted private key";
    };

    linkDestPub = mkOption {
      type = types.str;
      default = ".ssh/id_ed25519-home-manager.pub";
      description = "Path where to symlink the decrypted public key";
    };
  };

  config = mkIf cfg.enable (
    let
      userHome = config.users.users.${cfg.user}.home;
    in
    {
      age.secrets = {
        "${cfg.identityFile}" = {
          file = ../../secrets/ssh/id_ed25519-home-manager.age;
          owner = cfg.user;
          mode = "0400";
        };
        "${cfg.identityFilePub}" = {
          file = ../../secrets/ssh/id_ed25519-home-manager.pub.age;
          owner = cfg.user;
          mode = "0400";
        };
      };

      # Creates $HOME/.ssh dir for agenix to decrypt keys in home-manager agenix
      # note we let home-manager bitch if a file exists already.
      system.activationScripts.agenix-home-manager = mkAfter ''
        install -dm700 -o ${cfg.user} -g users "${userHome}/.ssh"

        ln -sf "${config.age.secrets.${cfg.identityFile}.path}" "${userHome}/${cfg.linkDest}"
        chown -h ${cfg.user}:users "${userHome}/${cfg.linkDest}"
        ln -sf "${config.age.secrets.${cfg.identityFilePub}.path}" "${userHome}/${cfg.linkDestPub}"
        chown -h ${cfg.user}:users "${userHome}/${cfg.linkDestPub}"
      '';
    }
  );
}
