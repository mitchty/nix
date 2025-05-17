{ inputs, config, ... }:
let
  username = "test";
  dir = "/home/${username}";
in
{
  system = "x86_64-linux";

  modules = [
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        #        config.propagationModule
        inputs.disko.nixosModules.disko
        ./diskconfig.nix
      ];

      system.stateVersion = "24.11";
      boot.loader.systemd-boot.enable = true;
      networking.hostName = "hm";

      users = {
        users.${username} = {
          isNormalUser = true;
          description = "Mitchell Tishmack";

          # TODO: some of these groups only apply if I got the right nixosmodule setup, need to brain how I handle that in future.
          extraGroups = [
            "wheel"
          ];
          home = dir;
          initialPassword = "changeme";
        };
      };

      #      home-manager.users.${username} = inputs'.self.homeConfigurations.test;
    }
  ];
}
