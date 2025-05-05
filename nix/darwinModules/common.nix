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

        # Like in nixos keep a copy of the current flake so I can diff if needed
        # to bisect issues.
        #
        # Need to get this and stuff like nix config to abuse this when I get to
        # unifying things between both os's:
        # https://github.com/rencire/flakelight-crossplatform
        etc."current-flake".source = ./../..;
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
        extraSpecialArgs = { inherit inputs; };
        users.mitch = {
          imports = with inputs.self.homeModules; [
            common
            emacs
          ];
        };
      };
    }
  ];
}
