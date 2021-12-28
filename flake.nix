{
  description = "mitchty nixos flake setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    master.url = "github:NixOS/nixpkgs/master";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # wip
    darwin.url = "github:NixOS/nixpkgs/nixpkgs-21.11-darwin";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "unstable";
    };
    # Follow same nixpkgs as the nixos release for the rest
    # Unless/until we find out that doesn't work
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "unstable";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "unstable";
    };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , master
    , nix-darwin
    , unstable
    , emacs-overlay
    , home-manager
    , nixos-generators
    , deploy-rs
    , ...
    }:
    let
      inherit (nix-darwin.lib) darwinSystem;
      inherit (inputs.unstable.lib) attrValues makeOverridable optionalAttrs singleton nixosSystem;

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
      nixOSModules = attrValues self.nixOSModules ++ [
        # ./nixos
        home-manager.nixosModules.home-manager
        (
          { config, lib, pkgs, ... }:
          let
            inherit (config.users) primaryUser;
          in
          {
            nixpkgs = nixpkgsConfig;
            users.users.${primaryUser}.home = "/home/${primaryUser}";
            home-manager.useGlobalPkgs = true;
            home-manager.users.${primaryUser} = homeManagerCommonConfig;
            nix.registry.my.flake = self;
          }
        )
      ];
    in
    {
      packages.x86_64-linux = {
        inherit unstable;
        iso = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          format = "iso";
        };
        install-iso = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          format = "install-iso";
        };
        x86iso = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./iso/configuration.nix
          ];
          format = "install-iso";
        };
      };

      darwinModules = {
        users = import ./modules/users.nix;
      };

      nixOSModules = {
        users = import ./modules/users.nix;
      };

      darwinConfigurations = rec {
        # Bootstrap configs for later...
        bootstrap-intel = makeOverridable darwinSystem {
          system = "x86_64-darwin";
          modules = [ ./darwin/bootstrap.nix { nixpkgs = nixpkgsConfig; } ];
        };
        # arm stuff for later?
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
        nexus = nixosSystem {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/nexus/configuration.nix
          ] ++ [{
            users.primaryUser = "mitch";
          }];
        };
        dfs1 = nixosSystem {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/dfs1/configuration.nix
          ] ++ [{
            users.primaryUser = "mitch";
          }];
        };
        # Work
        slaptop = nixosSystem {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/slaptop/configuration.nix
          ] ++ [{
            users.primaryUser = "mitch";
          }];
        };
      };

      # For home-manager to work
      mitch = self.homeConfigurations.mitch.activationPackage;
      defaultpackage.x86_64-linux = self.mitch;

      # TODO: More checks in place would be good
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
