{ inputs, ... }:
{

  system = "aarch64-darwin";
  modules = [
    inputs.home-manager.darwinModules.home-manager
    {
      imports = with inputs.self.darwinModules; [
        common
        laptop
        mutagen
        age
      ];

      networking.hostName = "mbp";

      users.users.mitch.home = "/Users/mitch";

      # We don't change these two from what they were installed with generally unless reinstalling.
      system = {
        stateVersion = 5;
        primaryUser = "mitch";
      };
      home-manager.users.mitch.home.stateVersion = "24.11";

      home-manager.users.mitch = {
        imports = with inputs.self.homeModules; [
          development
          gui
          macos
          mutagen
          macos-mitch
        ];
      };
    }
  ];
}
