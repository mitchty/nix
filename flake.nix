{
  description = "mitchty nixos flake setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    master.url = "github:NixOS/nixpkgs/master";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # wip
    darwin.url = "github:NixOS/nixpkgs/nixpkgs-21.11-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Follow same nixpkgs as the nixos release for the rest
    # Unless/until we find out that doesn't work
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "unstable";
    };
  };

  outputs = inputs@{ self, nixpkgs, master, nix-darwin, unstable, sops-nix, emacs-overlay, home-manager, deploy-rs, ... }:
    let
      inherit (nix-darwin.lib) darwinSystem;
      inherit (inputs.unstable.lib) attrValues makeOverridable optionalAttrs singleton;

      nixpkgsConfig = {
        config = { allowUnfree = true; };
        # overlays = attrValues self.overlays ++ [
        #   emacs-overlay.overlay
        # ];
        overlays = [
          emacs-overlay.overlay
        ];
        # TODO: later
        # singleton (
        #   # Sub in x86 version of packages that don't build on Apple Silicon yet
        #   final: prev: (optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
        #     inherit (final.pkgs-x86)
        #       idris2
        #       nix-index
        #       niv;
        #   })
        # );
      };

      homeManagerStateVersion = "22.05";
      homeManagerCommonConfig = {
        # imports = attrValues self.homeManagerModules ++ [
        imports = [
          ./home
          { home.stateVersion = homeManagerStateVersion; }
        ];
      };

      nixDarwinModules = attrValues self.darwinModules ++ [
        ./darwin
        home-manager.darwinModules.home-manager
        (
          { config, lib, pkgs, ... }:
          let
            inherit (config.users) primaryUser;
          in
          {
            nixpkgs = nixpkgsConfig;
            users.users.${primaryUser}.home = "/Users/${primaryUser}";
            home-manager.useGlobalPkgs = true;
            home-manager.users.${primaryUser} = homeManagerCommonConfig;
            nix.registry.my.flake = self;
          }
        )
      ];
    in
    {
      darwinModules = {
        users = import ./modules/darwin/users.nix;
      };
      # homeConfigurations = {
      #   # Shared home configuration between nixos/darwin
      #   mitch = inputs.home-manager.lib.homeManagerConfiguration {
      #     system = "x86_64-darwin";
      #     homeDirectory = "/home/mitch";
      #     username = "mitch";
      #     configuration = { config, pkgs, ... }: {
      #       imports = [
      #         ./users/mitch/home.nix
      #       ];
      #     };
      #   };
      # };
      # homeManagerModules = {
      #   imports = [./users/mitch/home.nix
      #             ];
      # };
      darwinConfigurations = rec {
        # Bootstrap configs for later...
        bootstrap-intel = makeOverridable darwinSystem {
          system = "x86_64-darwin";
          modules = [ ./darwin/bootstrap.nix { nixpkgs = nixpkgsConfig; } ];
        };
        bootstrap-arm = bootstrap-intel.override { system = "aarch64-darwin"; };
        mb = darwinSystem {
          system = "x86_64-darwin";
          modules = nixDarwinModules ++ [
            {
              users.primaryUser = "mitch";
              networking.computerName = "mb";
              networking.hostName = "mb";
              networking.knownNetworkServices = [
                "Wi-Fi"
                "USB 10/100/1000 LAN"
              ];
            }
          ];
        };
      };
      nixosConfigurations = {
        nexus = unstable.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nexus/configuration.nix
            sops-nix.nixosModules.sops
          ];
        };
      };

      # For home-manager to work
      mitch = self.homeConfigurations.mitch.activationPackage;
      defaultpackage.x86_64-linux = self.mitch;

      deploy = {
        sshUser = "mitch";
        user = "root";
        autoRollback = false;
        magicRollback = false;

        nodes = {
          "nexus" = {
            hostname = "10.10.10.200";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."nexus";
            };
          };
        };
      };
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
