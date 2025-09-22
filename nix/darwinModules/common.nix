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
      gui
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
        fonts.packages = [
          pkgs.comic-code

          pkgs.pragmata-pro
        ];
        # fontDir.enable = true; # nixos needs this

        # Avoids a login/out cycle most of the time for settings changes.
        # TODO: This resets all the window layouts and if I have emacs full
        # screen it moves around like a rabbit on crack every generation that is
        # applied. See if there is a way to figure out if there is a reason to
        # run this. I'm at a loss how however, maybe dump out all the stuff I've
        # defined and diff that vs what might be applied and if there is a
        # difference +/-/changed then run? I've zero clue how to approach that
        # though right now. Not high priority and maybe a better option is to
        # use window manager that respects where stuff is.
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
