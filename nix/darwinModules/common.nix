{
  inputs,
  config,
  pkgs,
  ...
}:

{
  # I'll always use home-manager on macos as its always used interactively
  #
  # So this is basically a bit like what I plan to do with nixos in separating out the interactive vs primarily server use of systems. That'll be more of a nixos thing though.
  imports = [
    inputs.home-manager.darwinModules.home-manager
    {
      nix = {
        package = pkgs.nix;
        # Lets things download in parallel but not too parallel
        #
        # Also enable nix flake and repl on flakes
        extraOptions = ''
          fallback = true
          binary-caches-parallel-connections = 4
          auto-optimise-store = false
          experimental-features = nix-command flakes
        '';
      };
      networking = {
        computerName = config.networking.hostName;
        localHostName = config.networking.hostName;
      };

      programs = {
        zsh.enable = true;
        bash.enable = true;
        direnv.enable = true; # need this one AND the home-manager one for this crap to work
      };

      environment = {
        variables.SHELL = "${pkgs.zsh}/bin/zsh";

        systemPackages = with pkgs; [
          jq
          git
        ];
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
        extraSpecialArgs = { inherit inputs; };
        users.mitch = {
          imports = with inputs.self.homeModules; [
            emacs
            git
            sh
          ];
          programs.direnv = {
            enable = true;
            stdlib = inputs.nixpkgs.lib.readFile ../../static/home/direnvrc;
            enableBashIntegration = true;
            enableFishIntegration = false;
            enableZshIntegration = true;
            nix-direnv = {
              enable = true;
            };
          };
          home.file.".canary".text = "ok";
        };
      };
    }
  ];
}
