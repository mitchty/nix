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
  environment.variables.EDITOR = "vi";

  age.secrets = {
    "secrets/passwd/root" = {
      file = ../../secrets/passwd/root.age;
    };
  };

  users = {
    # Only users I define
    mutableUsers = false;

    extraUsers.root.openssh.authorizedKeys.keys = [ pubKey ];
    users.root.hashedPasswordFile = config.age.secrets."secrets/passwd/root".path;
  };
}
