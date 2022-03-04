{
  description = "mitchty nixos flake setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    master.url = "github:NixOS/nixpkgs/master";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    mitchty = {
      url = "github:mitchty/nixos";
      inputs.nixpkgs.follows = "unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "unstable";
    };
    darwin.url = "github:NixOS/nixpkgs/nixpkgs-21.11-darwin";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "unstable";
    };
    # Follow same nixpkgs as the nixos release for the rest
    # Unless/until we find out that doesn't work
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
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "unstable";
    };
    emacs = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "unstable";
    };
    rust = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "unstable";
    };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , master
    , unstable
    , mitchty
    , flake-utils
    , nix-darwin
    , home-manager
    , nixos-generators
    , deploy-rs
    , sops
    , emacs
    , rust
    , ...
    }:
    let
      inherit (nix-darwin.lib) darwinSystem;
      inherit (nixpkgs.lib) attrValues makeOverridable optionalAttrs singleton nixosSystem mkIf;

      x86-linux = "x86_64-linux";
      stable = import nixpkgs {
        system = x86-linux;
      };

      homeDir = system: user: with nixpkgs.legacyPackages.${system}.stdenv;
        if isDarwin then
          "/Users/${user}"
        else if isLinux then
          "/home/${user}"
        else "";

      nixpkgsConfig = {
        overlays = [
          rust.overlay
          emacs.overlay
          # No longer neeeded here for future me to use to copypasta new patches
          # in if needed.
          # (self: super:
          #   rec {
          #     polkit = super.polkit.overrideAttrs (old: rec {
          #       patches = (old.patches or [ ]) ++ [ ./patches/polkit-cve-2021-4034.patch ];
          #     });
          #   })
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
        imports = attrValues {
          # TODO: for the future...
        } ++ [
          ./home
          { home.stateVersion = homeManagerStateVersion; }
        ];
      };

      nixDarwinModules = attrValues
        {
          users = import ./modules/users.nix;
        } ++ [
        sops.nixosModule
        home-manager.darwinModules.home-manager
        ./darwin
        (
          { config, lib, pkgs, ... }:
          let
            inherit (config.users) primaryUser;
          in
          {
            sops = {
              defaultSopsFile = ./secrets/passwd.yaml;
              age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
              secrets."users/mitch" = { };

              # https://github.com/Mic92/sops-nix/issues/65#issuecomment-929082304
              gnupg.sshKeyPaths = [ ];
            };

            nixpkgs = nixpkgsConfig;
            users.users.${primaryUser}.home = homeDir "x86_64-darwin" primaryUser;
            home-manager.useGlobalPkgs = true;
            home-manager.users.${primaryUser} = homeManagerCommonConfig;
            home-manager.extraSpecialArgs = {
              inherit inputs nixpkgs;
            };
            nix.registry.my.flake = self;
          }
        )
      ];

      nixOSModules = attrValues
        {
          users = import ./modules/users.nix;
        } ++ [
        sops.nixosModules.sops
        home-manager.nixosModules.home-manager
        ./modules/nixos
        (
          { config, lib, pkgs, ... }:
          let
            inherit (config.users) primaryUser;
          in
          {
            sops = {
              defaultSopsFile = ./secrets/passwd.yaml;
              age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
              secrets."users/root" = { };
              secrets."users/mitch" = { };

              # https://github.com/Mic92/sops-nix/issues/65#issuecomment-929082304
              gnupg.sshKeyPaths = [ ];
            };

            nixpkgs = nixpkgsConfig;
            users.users.${primaryUser}.home = homeDir "x86_64-linux" primaryUser;
            home-manager.useGlobalPkgs = true;
            home-manager.users.${primaryUser} = homeManagerCommonConfig;
            home-manager.extraSpecialArgs = {
              inherit inputs nixpkgs;
            };
            nix.registry.my.flake = self;
          }
        )
      ];

      dfs1Autoinstall = {
        autoinstall.flavor = "zfs";
        autoinstall.hostName = "dfs1";
        autoinstall.dedicatedBoot = "/dev/disk/by-id/ata-Hoodisk_SSD_J7TTC7A11230120";
        autoinstall.rootDevices = [
          "/dev/disk/by-id/ata-Samsung_Portable_SSD_T5_S4B0NR0RA00895L"
          "/dev/disk/by-id/ata-Samsung_Portable_SSD_T5_S4B0NR0RA01770E"
        ];
      };
    in
    {
      # TODO: Rebuild nexus via autoinstall
      # autoinstallIsoNexus = nixos-generators.nixosGenerate {
      #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
      #   modules = [
      #     ./iso/configuration.nix
      #     ./iso/iso.nix {
      #       # wipefs device before installing
      #       wipe = true;
      #       # dd /dev/zero before installing (can take a looooong time)
      #       zero = false;
      #       devices = [
      #         # nvme0n1
      #         "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_256GB_S2GLNXAH300325L"
      #         # nvme1n1
      #         "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_256GB_S2GLNXAH300329W"
      #       ];}
      #   ];
      #   format = "install-iso";
      # };
      packages.x86_64-linux = {
        sdGenericAarch64 = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux.pkgsCross.aarch64-multiplatform;
          modules = [ "${stable.path}/nixos/modules/profiles/minimal.nix" ];
          format = "sd-aarch64";
        };
        isoGeneric = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          format = "install-iso";
        };
        isoDfs1 = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            dfs1Autoinstall
            {
              autoinstall.wipe = true;
            }
          ];
          format = "install-iso";
        };
        isoZeroDfs1 = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            dfs1Autoinstall
            {
              autoinstall.wipe = true;
              autoinstall.zero = true;
            }
          ];
          format = "install-iso";
        };
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
        nexus = (makeOverridable nixosSystem) {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/nexus/configuration.nix
          ] ++ [{
            users.primaryUser = "mitch";
          }];
          specialArgs = { unstable = unstable.legacyPackages.${x86-linux}; };
        };
        dfs1 = nixosSystem {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/dfs1/configuration.nix
          ] ++ [{
            users.primaryUser = "mitch";
          }];
          specialArgs = { unstable = unstable.legacyPackages.${x86-linux}; };
        };
      };

      # Deploy-rs targets/setup
      deploy = {
        sshUser = "root";
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
          "dfs1" = {
            # hostname = "dfs1.local";
            hostname = "10.10.10.190";

            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."dfs1";
            };
          };
          # "mb" = {
          #   hostname = "mb.local";
          #   profiles.system = {
          #     path = deploy-rs.lib.x86_64-darwin.activate. self.darwinConfigurations."mb";
          #   };
          # };
        };
      };

      # TODO: More checks in place would be good
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    }; # // flake-utils.lib.eachDefaultSystem (system:
  #   let
  #     pkgs = import nixpkgs { inherit system overlays; };
  #     hm = home-manager.defaultPackage."${system}";
  #   in {
  #   }
  # );
}
