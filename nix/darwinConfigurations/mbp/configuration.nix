{ inputs, ... }:

{
  #  imports = [
  #    inputs.self.darwinModules.example
  #  ];

  #  networking.hostName = "m4p";
  #
  #  home-manager = {
  #    users.mitch = ./../homeModules/macos-mitch.nix;
  #  };

  #  users.users.mitch.home = "/Users/mitch";
}
