{
  description = "mitchty nixos flake setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    master.url = "github:NixOS/nixpkgs/master";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mitchty.url = "github:mitchty/nixos";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-21.11-darwin";

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "unstable";
    };

    # TODO: Future me fix so I can get updates to emacs 28.1 again via the
    # overlay. Figure out how to overlay this so emacs overlay works again.
    # https://github.com/lyderichti59/nixpkgs/commit/e2fa180f56918615d27fef71db14a0f79c60560b#diff-2d2a51ad7a5932155a18be815414a465f12097519b4192b8fe0b03cff4ca1252
    emacs.url = "github:nix-community/emacs-overlay/d969a968ee668d3ed646e056710c13f2efb9073a";

    home-manager.url = "github:nix-community/home-manager/release-21.11";
    nixos-generators.url = "github:nix-community/nixos-generators";
    deploy-rs.url = "github:serokell/deploy-rs";
    agenix-darwin.url = "github:montchr/agenix/darwin-support";
    agenix.url = "github:ryantm/agenix";
    rust = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "unstable";
    };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , unstable
    , mitchty
    , darwin
    , home-manager
    , nixos-generators
    , deploy-rs
    , emacs
    , rust
    , agenix-darwin
    , agenix
    , ...
    }:
    let
      inherit (darwin.lib) darwinSystem;
      inherit (nixpkgs.lib) attrValues makeOverridable nixosSystem;

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
          #       patches = (old.patches or [ ]) ++ [ ./patches/CVE-2021-4034.patch ];
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
        # Default roles is empty intentionally
        # defaultRoles = [ ];

        # mkNixOSSystem = { hostname, system, roles, users }: nixosSystem {
        #   system = "x86_64-linux";
        #   modules = nixOSModules ++ [
        #     ./hosts/nexus/configuration.nix
        #   ] ++ [{
        #     users.primaryUser = "mitch";
        #   }];
        # };
      };

      homeManagerStateVersion = "21.11";
      homeManagerCommonConfig = {
        imports = attrValues
          {
            # TODO: for the future...
          } ++ [
          { home.stateVersion = homeManagerStateVersion; }
          ./modules/home-manager
        ];
      };

      nixDarwinModules = attrValues
        {
          users = import ./modules/users.nix;
        } ++ [
        home-manager.darwinModules.home-manager
        ./modules/darwin
        agenix-darwin.darwinModules.age
        (
          { config, pkgs, ... }:
          let
            inherit (config.users) primaryUser;
          in
          {
            nixpkgs = nixpkgsConfig;
            users.users.${primaryUser}.home = homeDir "x86_64-darwin" primaryUser;
            home-manager.useGlobalPkgs = true;
            home-manager.users.${primaryUser} = homeManagerCommonConfig;
            home-manager.extraSpecialArgs = {
              inherit inputs nixpkgs;
              age = config.age;
            };
            nix.registry.my.flake = self;

            fonts = {
              fontDir.enable = true;
              # Need to move these derivations somewhere better
              fonts = [
                (pkgs.stdenv.mkDerivation rec {
                  pname = "comiccode";
                  version = "0.0.0";
                  nativeBuildInputs = [ pkgs.unzip ];
                  src = ./secrets/crypt/comic-code.zip;
                  sourceRoot = ".";
                  buildPhase = ''
                    find -name \*.otf
                  '';
                  installPhase = ''
                    install -dm755 $out/share/fonts/opentype/ComicCode
                    find -name \*.otf -exec mv {} $out/share/fonts/opentype/ComicCode \;
                  '';
                })
                (pkgs.stdenv.mkDerivation rec {
                  pname = "pragmatapro";
                  version = "0.0.0";
                  nativeBuildInputs = [ pkgs.unzip ];
                  src = ./secrets/crypt/pragmata-pro.zip;
                  sourceRoot = ".";
                  buildPhase = ''
                    find -name \*.ttf
                  '';
                  installPhase = ''
                    install -dm755 $out/share/fonts/truetype/PragmataPro
                    find -name \*.ttf -exec mv {} $out/share/fonts/truetype/PragmataPro \;
                  '';
                })
              ];
            };

            services.nix-index = {
              enable = true;
            };
          }
        )
      ];

      nixOSModules = attrValues
        {
          users = import ./modules/users.nix;
        } ++ [
        home-manager.nixosModules.home-manager
        ./modules/nixos
        agenix.nixosModules.age
        (
          { config, ... }:
          let
            inherit (config.users) primaryUser;
          in
          {
            nixpkgs = nixpkgsConfig;
            users.users.${primaryUser}.home = homeDir "x86_64-linux" primaryUser;
            home-manager.useGlobalPkgs = true;
            home-manager.users.${primaryUser} = homeManagerCommonConfig;
            home-manager.extraSpecialArgs = {
              inherit inputs nixpkgs;
              age = config.age;
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

      canarySecret = user: {
        canary = {
          file = ./secrets/canary.age;
          owner = user;
        };
      };

      gitSecret = user: {
        "git/netrc" = {
          file = ./secrets/git/netrc.age;
          owner = user;
        };
      };

      resticSecret = user: {
        "restic/env.sh" = {
          file = ./secrets/restic/env.sh.age;
          owner = user;
        };
      };

      passwdSecrets = {
        "passwd/root" = {
          file = ./secrets/passwd/root.age;
        };
        "passwd/mitch" = {
          file = ./secrets/passwd/mitch.age;
        };
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

      diskImages = {
        rpi4 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            # "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel.nix"
            # ./machines/ether/image.nix
            # ./machines/ether/hardware.nix
            # ./machines/ether/configuration.nix
          ];
        };
      };
      packages.x86_64-linux = {
        sdGenericAarch64 = nixos-generators.nixosGenerate {
          pkgs = unstable.legacyPackages.x86_64-linux.pkgsCross.aarch64-multiplatform;
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
          specialArgs = {
            inherit inputs;
          };
          system = "x86_64-darwin";
          modules = nixDarwinModules ++ [{
            users = {
              primaryUser = "mitch";
              primaryGroup = "staff";
            };
            age.secrets = canarySecret "mitch" // gitSecret "mitch" // resticSecret "mitch";
            networking.computerName = "mb";
            networking.hostName = "mb";
            networking.knownNetworkServices = [
              "Wi-Fi"
              "USB 10/100/1000 LAN"
            ];
            services.restic = {
              enable = true;
              repo = "s3:http://10.10.10.190:8333/restic";
            };
            services.mitchty = {
              enable = true;
            };
          }];
        };
        workmb = darwinSystem {
          system = "x86_64-darwin";
          modules = nixDarwinModules ++ [{
            users = {
              primaryUser = "tishmack";
              primaryGroup = "staff";
            };
            age.secrets = canarySecret "tishmack" // gitSecret "tishmack";
            networking.computerName = "workmb";
            networking.hostName = "workmb";
            networking.knownNetworkServices = [
              "Wi-Fi"
            ];
            services.work = {
              enable = true;
            };
            services.mitchty = {
              enable = true;
            };
          }];
        };
      };

      nixosConfigurations = {
        nexus = (makeOverridable nixosSystem) {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/nexus/configuration.nix
          ] ++ [{
            users = {
              primaryUser = "mitch";
              primaryGroup = "users";
            };
            age.secrets = canarySecret "mitch" // gitSecret "mitch" // resticSecret "mitch" // passwdSecrets;
          }];
          specialArgs = {
            inherit inputs;
            unstable = unstable.legacyPackages.${x86-linux};
          };
        };
        dfs1 = nixosSystem {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/dfs1/configuration.nix
          ] ++ [{
            users = {
              primaryUser = "mitch";
              primaryGroup = "users";
            };
            age.secrets = canarySecret "mitch" // gitSecret "mitch" // passwdSecrets;
          }];
          specialArgs = {
            inherit inputs;
            unstable = unstable.legacyPackages.${x86-linux};
          };
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
            hostname = "nexus.local";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."nexus";
            };
          };
          "dfs1" = {
            hostname = "dfs1.local";
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
      checks = builtins.mapAttrs (deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    }; # // flake-utils.lib.eachDefaultSystem (system:
  #   let
  #     pkgs = import nixpkgs { inherit system overlays; };
  #     hm = home-manager.defaultPackage."${system}";
  #   in {
  #   }
  # );
}
