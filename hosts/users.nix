{ pkgs, config, ... }:
let
  pubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7";
in
{
  # TODO: can home-manager sort this out now?
  # My normal user account
  config.users = {
    users = {
      root = {
        hashedPasswordFile = config.age.secrets."passwd/root".path;
      };
      mitch = {
        isNormalUser = true;
        description = "Mitchell James Tishmack";
        home = "/home/mitch";
        createHome = true;
        shell = pkgs.zsh;
        hashedPasswordFile = config.age.secrets."passwd/mitch".path;
        group = "users";
        extraGroups = [
          "audio"
          "docker"
          "jackaudio"
          "libvirtd"
          "networkmanager"
          "video"
          "wheel"
        ];
      };
    };

    # Only users I define
    mutableUsers = false;

    # Setup the above public key as an authorized key.
    extraUsers = {
      root.openssh.authorizedKeys.keys = [ pubKey ];
      mitch.openssh.authorizedKeys.keys = [ pubKey ];
    };
  };

  # allow passwordless sudo for wheel
  config.security.sudo.extraConfig = ''
    %wheel ALL=(root) NOPASSWD:ALL
  '';
}
