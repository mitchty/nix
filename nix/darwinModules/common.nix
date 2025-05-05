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
    with inputs.self.crossplatformModules;
    [ common ]
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

        # TODO: Go through the entire nix-darwin docs and find crap to toggle like a dumass.
        system = {
          defaults = {
            dock = {
              autohide = true;
              autohide-delay = 0.1;
              orientation = "bottom";
            };
            NSGlobalDomain.AppleShowAllExtensions = true;
            finder = {
              AppleShowAllExtensions = true;
              FXEnableExtensionChangeWarning = false;
              QuitMenuItem = true;
              ShowPathbar = true;
              _FXShowPosixPathInTitle = true;
            };
            CustomUserPreferences = {
              # For the force paste script
              "com.apple.scriptmenu" = {
                ScriptMenuEnabled = true;
                ShowLibraryScripts = false;
              };
              # Mostly here to make the menu bar a bit more useful
              "com.apple.systemuiserver" = {
                "NSStatusItem Visible Siri" = false;
                menuExtras = [
                  "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"
                  "/System/Library/CoreServices/Menu Extras/Clock.menu"
                ];
              };
              # Don't pollute network or usb fs's with .DS_Store turds
              "com.apple.desktopservices" = {
                DSDontWriteNetworkStores = true;
                DSDontWriteUSBStores = true;
              };
            };
          };
        };

        # Avoids a login/out cycle most of the time
        system.activationScripts.postuserActivation.text = ''
          $DRY_RUN_CMD /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
        '';

        environment.variables.SHELL = "${pkgs.zsh}/bin/zsh";

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
