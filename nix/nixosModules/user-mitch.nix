{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  # TODO: This needs to be shared across a root user setup and non at some point.
  pubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7";
in
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
      extraUsers.mitch.openssh.authorizedKeys.keys = [ pubKey ];
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
