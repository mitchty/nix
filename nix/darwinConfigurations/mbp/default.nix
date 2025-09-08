{ inputs, ... }:
{
  system = "aarch64-darwin";
  modules = [
    inputs.home-manager.darwinModules.home-manager
    {
      imports =
        with inputs.self.darwinModules;
        [
          common
          laptop
          mutagen
          age
          ollama
        ]
        ++ (with inputs.self.crossplatformModules; [
          mosh
          nix
        ]);

      services = {
        common.mosh.enable = true;
        mitchty.ollama.enable = false;
        shared.mutagen.enable = true;
      };

      networking.hostName = "mbp";

      users.users.mitch.home = "/Users/mitch";

      system = {
        # Don't change nix-darwin stateversion from what things were installed
        # with (unless rebuilding I guess, then do whatever, doesn't matter have
        # backups so nbd either way.
        stateVersion = 5;
        primaryUser = "mitch";
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        users.mitch = {
          # ditto home manager state version generally
          home.stateVersion = "24.11";
          imports = [
            inputs.agenix.homeManagerModules.default
          ]
          ++ (with inputs.self.homeModules; [
            development
            gui
            macos
            mutagen
            macos-mitch
            age
            sh
            tmux
            git
            git-age
          ]);
        };
      };
    }
  ];
}
