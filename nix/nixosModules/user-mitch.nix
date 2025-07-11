{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  config = {
    programs = {
      zsh.enable = true;
    };

    age.secrets = {
      "secrets/passwd/mitch" = {
        file = ../../secrets/passwd/mitch.age;
      };
    };

    users = {
      users.mitch = {
        isNormalUser = true;
        description = "Mitchell Tishmack";

        # TODO: some of these groups only apply if I got the right nixosmodule setup, need to brain how I handle that in future.
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        home = lib.mkDefault "/home/mitch";
        shell = pkgs.zsh;
        hashedPasswordFile = config.age.secrets."secrets/passwd/mitch".path;
      };
    };
  };
}
