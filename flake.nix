{
  description = "mitchty nixos flake setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    master.url = "github:NixOS/nixpkgs/master";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mitchty.url = "github:mitchty/nixos";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-22.05-darwin";

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # TODO: Set this up as an overlay or pr it to nixpkgs
    # https://github.com/lyderichti59/nixpkgs/commit/e2fa180f56918615d27fef71db14a0f79c60560b
    nixpkgs-mitchty.url = "github:/mitchty/nixpkgs/mitchty";
    emacs = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs-mitchty";
    };

    home-manager.url = "github:nix-community/home-manager/release-22.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs.url = "github:serokell/deploy-rs";
    agenix-darwin.url = "github:montchr/agenix/darwin-support";
    agenix.url = "github:ryantm/agenix";
    rust = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "unstable";
    };
    dnsblacklist = {
      url = "github:notracking/hosts-blocklists";
      flake = false;
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
    , dnsblacklist
    , flake-utils
    , ...
    }:
    let
      inherit (darwin.lib) darwinSystem;
      inherit (nixpkgs.lib) attrValues makeOverridable nixosSystem;

      x86-linux = "x86_64-linux";

      homeDir = system: user: with nixpkgs.legacyPackages.${system}.stdenv;
        if isDarwin then
          "/Users/${user}"
        else if isLinux then
          "/home/${user}"
        else "";

      nixpkgsConfig = {
        overlays = [
          emacs.overlay
          rust.overlays.default
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

      # Autoinstall vars

      # vm autoinstall test runners, note no by-id links cause qemu doens't get them
      simpleAutoinstall = {
        autoinstall = {
          flavor = "single";
          hostName = "simple";
          rootDevices = [
            "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001"
          ];
          bootSize = "512MiB";
          swapSize = "512MiB";
          osSize = "20GiB";
        };
      };

      # DL350 Gen9 server, for now zfs as bcachefs is marked broken in 22.05
      srvAutoinstall = {
        autoinstall = {
          flavor = "zfs";
          hostName = "srv";
          rootDevices = [
            "/dev/disk/by-id/wwn-0x5000cca02f0ae6a4"
            "/dev/disk/by-id/wwn-0x5000cca02f0bad08"
            "/dev/disk/by-id/wwn-0x5000cca02f0bbb04"
          ];
          swapSize = "16GiB";
          osSize = "538GiB";
        };
      };

      # Terramaster tm4-423 test
      sys1Autoinstall = {
        autoinstall = {
          flavor = "zfs";
          hostName = "sys1";
          rootDevices = [
            "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0T814942M"
            "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0T801235B"
          ];
          swapSize = "16GiB";
          osSize = "96GiB";
        };
      };

      # Current nas box, needs a rebuild once dfs2/3 are working
      dfs1Autoinstall = {
        autoinstall.flavor = "zfs";
        autoinstall.hostName = "dfs1";
        autoinstall.dedicatedBoot = "/dev/disk/by-id/ata-Hoodisk_SSD_J7TTC7A11230120";
        autoinstall.rootDevices = [
          "/dev/disk/by-id/ata-Samsung_Portable_SSD_T5_S4B0NR0RA00895L"
          "/dev/disk/by-id/ata-Samsung_Portable_SSD_T5_S4B0NR0RA01770E"
        ];
      };

      # NixOS router, I'm sick of naming things cute names
      gwAutoinstall = {
        autoinstall = {
          osSize = "108GiB";
          flavor = "single";
          hostName = "gw";
          rootDevices = [
            "/dev/disk/by-id/ata-KINGSTON_SA400M8120G_50026B7684B2F04E"
          ];
        };
      };

      # NixOS nexus system, does most of the heavy lifting, needs a
      # rebuild/restore too once the "final" dfs backup stuffs working
      nexusAutoinstall = {
        autoinstall.flavor = "zfs";
        autoinstall.hostName = "nexus";
        autoinstall.rootDevices = [
          "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_256GB_S2GLNXAH300325L"
          "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_256GB_S2GLNXAH300329W"
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

      ghcliPubSecret = user: {
        "git/gh-cli-pub" = {
          file = ./secrets/git/gh-cli-pub.age;
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
        # vmSimple = nixos-generators.nixosGenerate {
        #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
        #   modules = [
        #     ./modules/iso/autoinstall.nix
        #     simpleAutoinstall
        #     {
        #       autoinstall.debug = true;
        #       autoinstall.wipe = true;
        #     }
        #   ];
        #   format = "vm-nogui";
        # };
        isoSimple = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            simpleAutoinstall
            {
              autoinstall.debug = true;
            }
          ];
          format = "install-iso";
        };
        isoSrv = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            srvAutoinstall
            {
              autoinstall.debug = true;
              autoinstall.wipe = true;
            }
          ];
          format = "install-iso";
        };
        isoSys1 = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            sys1Autoinstall
            {
              autoinstall.debug = true;
              autoinstall.wipe = true;
            }
          ];
          format = "install-iso";
        };
        isoGw = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            gwAutoinstall
            {
              autoinstall.debug = true;
              autoinstall.wipe = true;
            }
          ];
          format = "install-iso";
        };
        # sdGenericAarch64 = nixos-generators.nixosGenerate {
        #   pkgs = nixpkgs.legacyPackages.x86_64-linux.pkgsCross.aarch64-multiplatform;
        #   modules = [ "${nixpkgs.legacyPackages.aarch64-linux.path}/nixos/modules/profiles/minimal.nix" ];
        #   format = "sd-aarch64";
        # };
        # isoGeneric = nixos-generators.nixosGenerate {
        #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
        #   format = "install-iso";
        # };
        # isoDfs1 = nixos-generators.nixosGenerate {
        #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
        #   modules = [
        #     ./modules/iso/autoinstall.nix
        #     dfs1Autoinstall
        #     {
        #       autoinstall.wipe = true;
        #     }
        #   ];
        #   format = "install-iso";
        # };
        # isoZeroDfs1 = nixos-generators.nixosGenerate {
        #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
        #   modules = [
        #     ./modules/iso/autoinstall.nix
        #     dfs1Autoinstall
        #     {
        #       autoinstall.wipe = true;
        #       autoinstall.zero = true;
        #     }
        #   ];
        #   format = "install-iso";
        # };
        # isoZeroRouter = nixos-generators.nixosGenerate {
        #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
        #   modules = [
        #     ./modules/iso/autoinstall.nix
        #     routerAutoinstall
        #     {
        #       autoinstall.debug = true;
        #       autoinstall.wipe = true;
        #       autoinstall.zero = true;
        #     }
        #   ];
        #   format = "install-iso";
        # };
        # isoNexus = nixos-generators.nixosGenerate {
        #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
        #   modules = [
        #     ./modules/iso/autoinstall.nix
        #     nexusAutoinstall
        #     {
        #       autoinstall.wipe = true;
        #     }
        #   ];
        #   format = "install-iso";
        # };
        # isoZeroNexus = nixos-generators.nixosGenerate {
        #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
        #   modules = [
        #     ./modules/iso/autoinstall.nix
        #     nexusAutoinstall
        #     {
        #       autoinstall.wipe = true;
        #       autoinstall.zero = true;
        #     }
        #   ];
        #   format = "install-iso";
        # };
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
            age.secrets = canarySecret "mitch" // gitSecret "mitch" // ghcliPubSecret "mitch" // resticSecret "mitch";
            # Since I use this host for working on all this crap, need a get out
            # of jail free card on dns, but nice for it to search home.arpa by
            # default too so I can be lazy.
            networking = {
              computerName = "mb";
              hostName = "mb";
              dns = [ "10.10.10.1" "1.1.1.1" ];
              search = [ "home.arpa" ];
              knownNetworkServices = [
                "Wi-Fi"
                "USB 10/100/1000 LAN"
              ];
            };
            services.restic = {
              enable = true;
              repo = "s3:http://dfs1.home.arpa:8333/restic";
            };
            services.mitchty = {
              enable = true;
            };
            services.home = {
              enable = true;
            };
          }];
        };
        wmb = darwinSystem {
          inherit inputs;
          system = "x86_64-darwin";
          modules = nixDarwinModules ++ [{
            users = {
              primaryUser = "tishmack";
              primaryGroup = "staff";
            };
            age.secrets = canarySecret "tishmack" // gitSecret "tishmack" // ghcliPubSecret "tishmack";
            networking.computerName = "wmb";
            networking.hostName = "wmb";
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
        gw = (makeOverridable nixosSystem) {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/gw/configuration.nix
          ] ++ [{
            users = {
              primaryUser = "mitch";
              primaryGroup = "users";
            };
            age.secrets = canarySecret "mitch" // gitSecret "mitch" // ghcliPubSecret "tishmack" // passwdSecrets;
            services.role = {
              intel.enable = true;
              mosh.enable = true;
              node-exporter.enable = true;
              promtail.enable = true;
              router.enable = true;
            };
          }];
          specialArgs = {
            inherit inputs;
            unstable = unstable.legacyPackages.${x86-linux};
          };
        };
        srv = (makeOverridable nixosSystem) {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/srv/configuration.nix
          ] ++ [{
            users = {
              primaryUser = "mitch";
              primaryGroup = "users";
            };
            age.secrets = canarySecret "mitch" // gitSecret "mitch" // ghcliPubSecret "mitch" // resticSecret "mitch" // passwdSecrets;
            services.role = {
              grafana.enable = true;
              gui.enable = true;
              highmem.enable = true;
              intel.enable = true;
              loki.enable = true;
              mosh.enable = true;
              node-exporter.enable = true;
              nixcache.enable = true;
              prometheus.enable = true;
              promtail.enable = true;
              syncthing.enable = true;
            };
          }];
          specialArgs = {
            inherit inputs;
            unstable = unstable.legacyPackages.${x86-linux};
          };
        };
        nexus = (makeOverridable nixosSystem) {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/nexus/configuration.nix
          ] ++ [{
            users = {
              primaryUser = "mitch";
              primaryGroup = "users";
            };
            age.secrets = canarySecret "mitch" // gitSecret "mitch" // ghcliPubSecret "mitch" // resticSecret "mitch" // passwdSecrets;
            services.role = {
              gui.enable = true;
              intel.enable = true;
              mosh.enable = true;
              node-exporter.enable = true;
              promtail.enable = true;
              syncthing.enable = true;
            };
          }];
          specialArgs = {
            inherit inputs;
            unstable = unstable.legacyPackages.${x86-linux};
          };
        };
        sys1 = (makeOverridable nixosSystem) {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/sys1/configuration.nix
          ] ++ [{
            users = {
              primaryUser = "mitch";
              primaryGroup = "users";
            };
            age.secrets = canarySecret "mitch" // gitSecret "mitch" // ghcliPubSecret "mitch" // passwdSecrets;
            services.role = {
              intel.enable = true;
              mosh.enable = true;
              node-exporter.enable = true;
              promtail.enable = true;
            };
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
            services.role = {
              intel.enable = true;
              lowmem.enable = true;
              mosh.enable = true;
              node-exporter.enable = true;
              promtail.enable = true;
            };
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
          "gw" = {
            hostname = "gw.home.arpa";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."gw";
            };
          };
          "srv" = {
            hostname = "srv.home.arpa";
            # hostname = "10.10.10.117";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."srv";
            };
          };
          "nexus" = {
            hostname = "nexus.home.arpa";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."nexus";
            };
          };
          "sys1" = {
            hostname = "sys1.home.arpa";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."sys1";
            };
          };
          "dfs1" = {
            hostname = "dfs1.home.arpa";
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

      checks.deploy-rs = builtins.mapAttrs
        (deployLib: deployLib.deployChecks self.deploy)
        deploy-rs.lib;
    } // flake-utils.lib.eachDefaultSystem
      (system:
      let pkgs = import nixpkgs { inherit system; };
      in
      rec {
        checks = {
          nixpkgs-fmt = pkgs.runCommand "check-nix-format" { } ''
            ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}
            install -dm755 $out
          '';
        };
      }
      );
}
