{
  inputs,
  config,
  pkgs,
  ...
}:

{
  # I'll always use home-manager on macos as its always used interactively
  #
  # So this is basically a bit like what I plan to do with nixos in separating
  # out the interactive vs primarily server use of systems. That'll be more of a
  # nixos thing though.
  imports =
    (with inputs.self.crossplatformModules; [ common ])
    ++ (with inputs.self.darwinModules; [
      finder
      dock
      defaults
    ])
    ++ [
      inputs.home-manager.darwinModules.home-manager
      {
        networking = {
          computerName = config.networking.hostName;
          localHostName = config.networking.hostName;
        };

        programs = {
          zsh.enable = true;
          bash.enable = true;
          direnv.enable = true; # need this one AND the home-manager one for this crap to work it seems.
        };

        # TODO: Think this needs to become a common module
        fonts.packages = [ pkgs.paid-fonts ];
        # fontDir.enable = true; # nixos needs this

        # Avoids a login/out cycle most of the time
        system.activationScripts.postuserActivation.text = ''
          $DRY_RUN_CMD /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
        '';

        environment = {
          variables.SHELL = "${pkgs.zsh}/bin/zsh";
          # We're building from a flake this is for channel nonsense/configuration.nix shenanigans
          darwinConfig = null;
        };

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "bak";
          extraSpecialArgs = { inherit inputs; };
          users.mitch = {
            imports = with inputs.self.homeModules; [
              common
            ];
          };
        };
      }
    ];
}
