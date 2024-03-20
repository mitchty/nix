{
  description = "mitchty nixos flake setup";

  inputs = {
    # This is evil but I'm sick of commenting things out
    #
    # The premise is this is the "default" and if I want to do a build without
    # it I pass it in as an arg.
    # like so nix build --override-input with-homecache github:boolean-option/false
    with-homecache.url = "github:boolean-option/true";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    latest.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mitchty.url = "github:mitchty/nixos";
    # mitchty.url = "path:/Users/mitch/src/pub/github.com/mitchty/nixos";
    # mitchty.url = "path:/Users/tishmack/src/pub/github.com/mitchty/nixos";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";
    nixpkgs-pacemaker.url = "github:mitchty/nixpkgs/corosync-pacemaker-ocf";
    # nixpkgs-pacemaker.url = "path:/Users/mitch/src/pub/github.com/mitchty/nixpkgs@pacemaker";

    nil.url = "github:oxalica/nil";

    nur.url = "github:nix-community/NUR";

    # Until I can debug the dyld segfault with 23.11 pin darwin to 23.05 as a
    # very hacky way to have things work.
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dnsblacklist = {
      url = "github:notracking/hosts-blocklists";
      flake = false;
    };

    # nixinit.url = "github:nix-community/nix-init";
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , latest
    , mitchty
    , darwin
    , home-manager
    , disko
    , nixos-generators
    , deploy-rs
    , emacs-overlay
    , rust
    , agenix
    , dnsblacklist
    , flake-utils
    , nixpkgs-pacemaker
    , nur
    , nil
      # , terraform-old
      # , nixinit
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

      # Local overlays to nixpkgs
      localOverlays = ./overlays;
      myOverlays = with builtins; map (n: import (localOverlays + ("/" + n)))
        (filter
          (n: match ".*\\.nix" n != null ||
            pathExists (localOverlays + ("/" + n + "/default.nix")))
          (attrNames (readDir localOverlays)));

      # Local role setup for combined nixos/darwin stuff
      localRoles = ./modules/roles;
      myRoles = with builtins; map (n: import (myRoles + ("/" + n)))
        (filter
          (n: match ".*\\.nix" n != null ||
            pathExists (myRoles + ("/" + n + "/default.nix")))
          (attrNames (readDir myRoles)));

      nixpkgsOverlays = [
        emacs-overlay.overlay
        rust.overlays.default
        nur.overlay
        nil.overlays.default
      ] ++ myOverlays ++ [
        # Note these come after ^^^ as they use some things those overlays define
        # TODO: this stuff should all get put into a flake overlay in this repo
        # stop being lazy, just not sure how to pass in the custom pacemaker
        # nixpkgs to do it.
        (
          # force in the ocf-resource-agents/pacemaker I patched into nixpkgs-pacemaker
          # ignore system as for now all it runs on is x86_64-linux so
          # whatever
          final: prev: rec {
            pacemaker = nixpkgs-pacemaker.legacyPackages.x86_64-linux.pacemaker;
            ocf-resource-agents = nixpkgs-pacemaker.legacyPackages.x86_64-linux.ocf-resource-agents;
          }
        )
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

      nixpkgsConfig = extras: {
        overlays = nixpkgsOverlays ++ extras;
        # config.permittedInsecurePackages = [ "garage-0.7.3" ];
        config.permittedInsecurePackages = [ "python3.10-django-3.1.14" ];
        config.allowUnfree = true;
      };

      homeManagerStateVersion = "21.11";
      homeManagerCommonConfig = {
        imports = attrValues
          {
            # TODO: for the future...
          } ++ [
          { home.stateVersion = homeManagerStateVersion; }
          ./modules/home-manager
          #          nur.hmModules
        ];
      };

      nixDarwinModules = attrValues
        {
          users = import ./modules/users.nix;
        } ++ [
        home-manager.darwinModules.home-manager
        ./modules/darwin
        ./modules/roles/gui.nix
        #      ] ++ myRoles ++ [
        agenix.darwinModules.age
        (
          { config, pkgs, ... }:
          let
            inherit (config.users) primaryUser;
          in
          {
            nixpkgs = nixpkgsConfig [ ];
            users.users.${primaryUser}.home = homeDir "x86_64-darwin" primaryUser;
            home-manager.useGlobalPkgs = true;
            home-manager.users.${primaryUser} = homeManagerCommonConfig;
            home-manager.extraSpecialArgs = {
              inherit inputs nixpkgs;
              inherit (config) age roles;
            };
            nix.registry.my.flake = self;

            services.nix-index = {
              enable = true;
            };
          }
        )
      ];

      pacemakerPath = "services/cluster/pacemaker/default.nix";

      nixOSModules = attrValues
        {
          users = import ./modules/users.nix;
        } ++ [
        home-manager.nixosModules.home-manager
        nur.nixosModules.nur
        ./modules/nixos
        #      ] ++ myRoles ++ [
        (import ./modules/roles/gui.nix)
        agenix.nixosModules.age
        "${inputs.nixpkgs-pacemaker}/nixos/modules/${pacemakerPath}"
        (
          { config, ... }:
          let
            inherit (config.users) primaryUser;
          in
          {
            # From: https://github.com/NixOS/nixpkgs/blob/c653577537d9b16ffd04e3e2f3bc702cacc1a343/nixos/doc/manual/development/replace-modules.section.md
            #
            # TODO: Remove most of me once
            # https://github.com/NixOS/nixpkgs/pull/208298/files merged Disable the built.
            #
            # in pacemaker module in lieu of my fixed version until the basic version is
            # merged.
            #
            # Will also be testing out some other module updates to make it less of a PITA to use.
            disabledModules = [ pacemakerPath ];

            nixpkgs = nixpkgsConfig [ ];
            users.users.${primaryUser}.home = homeDir "x86_64-linux" primaryUser;
            home-manager.useGlobalPkgs = true;
            home-manager.users.${primaryUser} = homeManagerCommonConfig;
            home-manager.extraSpecialArgs = {
              inherit inputs nixpkgs;
              inherit (config) age roles;
            };
            nix.registry.my.flake = self;
          }
        )
      ];

      # Autoinstall vars
      defBootSize = "512MiB";
      defSwapSize = "16GiB";
      smallSwapSize = "512MiB";

      # vm autoinstall test runners
      simpleAutoinstall = {
        autoinstall = {
          flavor = "single";
          hostName = "simple";
          rootDevices = [
            "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001"
          ];
          bootSize = defBootSize;
          swapSize = smallSwapSize;
          osSize = "20GiB";
        };
      };

      # Two disk test
      zfsAutoinstall = {
        autoinstall = {
          flavor = "zfs";
          hostName = "zfs";
          rootDevices = [
            "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001"
            "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00002"
          ];
          bootSize = defBootSize;
          swapSize = smallSwapSize;
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
          swapSize = defSwapSize;
          osSize = "538GiB";
        };
      };

      cluOsSize = "768GiB";

      wm2Autoinstall = {
        autoinstall = {
          flavor = "zfs";
          hostName = "wm2";
          rootDevices = [
            "/dev/disk/by-id/nvme-CWESR02TBTLCZ-27J-2_511231016041001198"
            "/dev/disk/by-id/nvme-Sabrent_Rocket_Q4_48821081708402"
          ];
          swapSize = defSwapSize;
          osSize = "1840GiB";
        };
      };

      # Start of a Terramaster tm4-423 cluster
      cl1Autoinstall = {
        autoinstall = {
          flavor = "zfs";
          hostName = "cl1";
          rootDevices = [
            "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0T918828M"
            "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0T920857X"
          ];
          swapSize = defSwapSize;
          osSize = cluOsSize;
        };
      };

      # Second node
      cl2Autoinstall = {
        autoinstall = {
          flavor = "zfs";
          hostName = "cl2";
          rootDevices = [
            "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0T814942M"
            "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0T801235B"
          ];
          swapSize = defSwapSize;
          osSize = cluOsSize;
        };
      };

      # Third node
      cl3Autoinstall = {
        autoinstall = {
          flavor = "zfs";
          hostName = "cl3";
          rootDevices = [
            "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0T918913H"
            "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0T924424L"
          ];
          swapSize = defSwapSize;
          osSize = cluOsSize;
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

      wifiSecrets = user: {
        "wifi/passphrase" = {
          file = ./secrets/wifi/passphrase.age;
          owner = user;
        };
      };

      # Make age.secrets = a bit simpler with some defined variables
      homeUser = "mitch";
      homeGroup = "users";

      workUser = "tishmack";
      rootUser = "root";

      ageDefault = user: canarySecret user;
      ageGit = user: gitSecret user // ghcliPubSecret user;
      ageRestic = user: resticSecret user;

      ageHome = user: ageDefault user // ageGit user;
      ageHomeWithBackup = user: ageHome user // ageRestic user;
      ageHomeNixos = user: ageHome user // passwdSecrets;
      ageHomeNixosWithBackup = user: ageHomeNixos user // ageRestic user;
    in
    {
      packages.x86_64-linux = {
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
        isoSimpleTest = nixos-generators.nixosGenerate {
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
        isoZfsTest = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            zfsAutoinstall
            {
              autoinstall.debug = true;
            }
          ];
          format = "install-iso";
        };
        isoWm2 = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            wm2Autoinstall
            {
              autoinstall = {
                wipe = true;
                debug = true;
              };
            }
          ];
          format = "install-iso";
        };
        isoCl1 = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            cl1Autoinstall
            {
              autoinstall.debug = true;
              autoinstall.wipe = true;
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
              primaryUser = homeUser;
              primaryGroup = "staff";
            };
            age.secrets = ageHomeWithBackup homeUser;
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
            roles.gui = {
              enable = true;
              isDarwin = true;
            };
            services.restic = {
              enable = true;
              repo = "s3:http://cluster.home.arpa:3900/restic/";
            };
            services.home.enable = true;
            services.mitchty.enable = true;
            services.shared.mutagen.enable = true;
          }];
        };
      };

      nixosConfigurations = {
        # Note this configuration is just to test out auto iso image creation.
        # simple = (makeOverridable nixosSystem) rec {
        #   system = "x86_64-linux";
        #   modules = nixOSModules ++ [
        #     ./hosts/simple/configuration.nix
        #   ] ++ [{
        #     users = {
        #       primaryUser = homeUser;
        #       primaryGroup = homeGroup;
        #     };
        #     age.secrets = ageHomeNixos homeUser;
        #     services.role = {
        #       mosh.enable = true;
        #     };
        #   }];
        #   specialArgs = {
        #     inherit inputs;
        #     latest = latest.legacyPackages.${x86-linux};
        #   };
        # };
        gw = (makeOverridable nixosSystem) rec {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/gw/configuration.nix
          ] ++ [{
            users = {
              primaryUser = homeUser;
              primaryGroup = homeGroup;
            };
            age.secrets = ageHomeNixos homeUser // wifiSecrets rootUser;
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
            latest = latest.legacyPackages.${x86-linux};
          };
        };
        srv = (makeOverridable nixosSystem) {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/srv/configuration.nix
          ] ++ [{
            users = {
              primaryUser = homeUser;
              primaryGroup = homeGroup;
            };
            age.secrets = ageHomeNixosWithBackup homeUser;
            services.role = {
              media = {
                enable = true;
                services = true;
              };

              qemu.enable = true;
              grafana.enable = true;
              highmem.enable = true;
              intel.enable = true;
              loki.enable = true;
              mosh.enable = true;
              node-exporter.enable = true;
              nixcache.enable = true;
              prometheus.enable = true;
              promtail.enable = true;
            };
            services.shared.mutagen = {
              enable = true;
              user = homeUser;
              group = homeGroup;
            };
          }];
          specialArgs = {
            inherit inputs;
            latest = latest.legacyPackages.${x86-linux};
          };
        };
        wm2 =
          (makeOverridable nixosSystem)
            rec {
              system = "x86_64-linux";
              modules = nixOSModules ++ [
                ./hosts/wm2/configuration.nix
              ] ++ [{
                users = {
                  primaryUser = homeUser;
                  primaryGroup = homeGroup;
                };
                age.secrets = ageHomeNixos homeUser;
                roles.gui = {
                  enable = true;
                  isLinux = true;
                };
                services.role = {
                  gaming.enable = true;
                  qemu.enable = true;
                  intel.enable = true;
                  mosh.enable = true;
                  node-exporter.enable = true;
                  promtail.enable = true;
                };
                services.shared.mutagen = {
                  enable = true;
                  user = homeUser;
                  group = homeGroup;
                };
              }];
              specialArgs = {
                inherit inputs;
                latest = latest.legacyPackages.${x86-linux};
              };
            };
        cl1 = (makeOverridable nixosSystem)
          {
            system = "x86_64-linux";
            modules = nixOSModules ++ [
              ./hosts/cl1/configuration.nix
            ] ++ [{
              users = {
                primaryUser = homeUser;
                primaryGroup = homeGroup;
              };
              age.secrets = ageHomeNixos homeUser;
              services.role = {
                cluster.enable = true;
                intel.enable = true;
                mosh.enable = true;
                promtail.enable = true;
                node-exporter = {
                  enable = true;
                  exporterIface = "enp1s0";
                };
              };
              fileSystems = {
                # mkfs.ext4 -j /dev/disk/by-id/ata-WDC_WUH722020ALE6L4_2LG3R54F
                "/data/disk/0" = {
                  device = "/dev/disk/by-id/ata-WDC_WUH722020ALE6L4_2LG3R54F";
                  fsType = "ext4";
                  options = [ "nofail" ];
                };
                # # mkfs.xfs /dev/disk/by-id/ata-WDC_WD30EFRX-68AX9N0_WD-WCC1T1098132
                # "/data/disk/1" = {
                #   device = "/dev/disk/by-id/ata-WDC_WD30EFRX-68AX9N0_WD-WCC1T1098132";
                #   fsType = "xfs";
                #   options = [ "nofail" ];
                # };
                # # mkfs.xfs /dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N4CVRRUX
                # "/data/disk/2" = {
                #   device = "/dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N4CVRRUX";
                #   fsType = "xfs";
                #   options = [ "nofail" ];
                # };
                # # mkfs.xfs /dev/disk/by-id/ata-WDC_WD30EZRX-00MMMB0_WD-WCAWZ2948041
                # "/data/disk/3" = {
                #   device = "/dev/disk/by-id/ata-WDC_WD30EZRX-00MMMB0_WD-WCAWZ2948041";
                #   fsType = "xfs";
                #   options = [ "nofail" ];
                # };
              };
            }];
            specialArgs = {
              inherit inputs;
              latest = latest.legacyPackages.${x86-linux};
            };
          };
        cl2 = (makeOverridable nixosSystem)
          {
            system = "x86_64-linux";
            modules = nixOSModules ++ [
              ./hosts/cl2/configuration.nix
            ] ++ [{
              users = {
                primaryUser = homeUser;
                primaryGroup = homeGroup;
              };
              age.secrets = ageHomeNixos homeUser;
              services.role = {
                cluster.enable = true;
                intel.enable = true;
                mosh.enable = true;
                promtail.enable = true;
                node-exporter = {
                  enable = true;
                  exporterIface = "enp1s0";
                };
              };

              fileSystems = {
                # mkfs.ext4 -j /dev/disk/by-id/ata-WDC_WUH722020ALE6L4_2LG929NF
                "/data/disk/0" = {
                  device = "/dev/disk/by-id/ata-WDC_WUH722020ALE6L4_2LG929NF";
                  fsType = "ext4";
                  options = [ "nofail" ];
                };
                # # mkfs.xfs /dev/disk/by-id/ata-WDC_WD30EZRX-00MMMB0_WD-WMAWZ0339419
                # "/data/disk/1" = {
                #   device = "/dev/disk/by-id/ata-WDC_WD30EZRX-00MMMB0_WD-WMAWZ0339419";
                #   fsType = "xfs";
                #   options = [ "nofail" ];
                # };
                # # mkfs.xfs /dev/disk/by-id/ata-ST8000NM0055-1RM112_ZA15CRCT
                # "/data/disk/2" = {
                #   device = "/dev/disk/by-id/ata-ST8000NM0055-1RM112_ZA15CRCT";
                #   fsType = "xfs";
                #   options = [ "nofail" ];
                # };
                # # mkfs.xfs /dev/disk/by-id/ata-WDC_WD30EZRX-00MMMB0_WD-WCAWZ2831437
                # "/data/disk/3" = {
                #   device = "/dev/disk/by-id/ata-WDC_WD30EZRX-00MMMB0_WD-WCAWZ2831437";
                #   fsType = "xfs";
                #   options = [ "nofail" ];
                # };
              };
            }];
            specialArgs = {
              inherit inputs;
              latest = latest.legacyPackages.${x86-linux};
            };
          };
        cl3 = (makeOverridable nixosSystem)
          {
            system = "x86_64-linux";
            modules = nixOSModules ++ [
              ./hosts/cl3/configuration.nix
            ] ++ [{
              users = {
                primaryUser = homeUser;
                primaryGroup = homeGroup;
              };
              age.secrets = ageHomeNixos homeUser;
              services.role = {
                cluster.enable = true;
                intel.enable = true;
                mosh.enable = true;
                promtail.enable = true;
                node-exporter = {
                  enable = true;
                  exporterIface = "enp1s0";
                };
              };
              fileSystems = {
                # mkfs.ext4 -j /dev/disk/by-id/ata-WDC_WUH722020ALE6L4_2LG8P50F
                "/data/disk/0" = {
                  device = "/dev/disk/by-id/ata-WDC_WUH722020ALE6L4_2LG8P50F";
                  fsType = "ext4";
                  options = [ "nofail" ];
                };
                # # mkfs.xfs /dev/disk/by-id/ata-WDC_WD30EZRX-00MMMB0_WD-WCAWZ2936180
                # "/data/disk/1" = {
                #   device = "/dev/disk/by-id/ata-WDC_WD30EZRX-00MMMB0_WD-WCAWZ2936180";
                #   fsType = "xfs";
                #   options = [ "nofail" ];
                # };
                # # mkfs.xfs /dev/disk/by-id/ata-ST8000NM0055-1RM112_ZA173E83
                # "/data/disk/2" = {
                #   device = "/dev/disk/by-id/ata-ST8000NM0055-1RM112_ZA173E83";
                #   fsType = "xfs";
                #   options = [ "nofail" ];
                # };
                # # mkfs.xfs /dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N4XFTFFS
                # "/data/disk/3" = {
                #   device = "/dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N4XFTFFS";
                #   fsType = "xfs";
                #   options = [ "nofail" ];
                # };
              };
            }];
            specialArgs = {
              inherit inputs;
              latest = latest.legacyPackages.${x86-linux};
            };
          };
        dfs1 = nixosSystem
          {
            system = "x86_64-linux";
            modules = nixOSModules ++ [
              ./hosts/dfs1/configuration.nix
            ] ++ [{
              users = {
                primaryUser = homeUser;
                primaryGroup = homeGroup;
              };
              age.secrets = ageHomeNixos homeUser;
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
              latest = latest.legacyPackages.${x86-linux};
            };
          };
      };

      # Deploy-rs targets/setup
      deploy = {
        sshUser = "root";
        user = "root";
        autoRollback = true;
        magicRollback = true;

        nodes = {
          "simple" = {
            hostname = "simple.home.arpa";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."simple";
            };
          };
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
          "wm2" = {
            hostname = "10.10.10.115";
            #            hostname = "localhost";
            #            hostname = "wm2.home.arpa";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."wm2";
            };
          };
          "local-wm2" = {
            hostname = "localhost";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."wm2";
            };
          };
          "cl1" = {
            hostname = "cl1.home.arpa";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."cl1";
            };
          };
          "cl2" = {
            hostname = "cl2.home.arpa";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."cl2";
            };
          };
          "cl3" = {
            hostname = "cl3.home.arpa";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."cl3";
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
      # checks.nixpkgs-fmt = nixpkgs.runCommand "check-nix-format" { } ''
      #   ${nixpkgs.legacyPackages.${system}.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}
      #   install -dm755 $out
      # '';
    } // flake-utils.lib.eachDefaultSystem
      (system:
      # let pkgs = nixpkgsConfig [ ];
      let pkgs = import nixpkgs { inherit system; };
      in
      rec {
        checks = {
          nixpkgs-fmt = pkgs.runCommand "check-nix-format" { } ''
            ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}
            install -dm755 $out
          '';
          shellcheck = pkgs.runCommand "check-shellcheck" { } ''
            ${pkgs.shellcheck}/bin/shellcheck --severity warning --shell sh $(find ${./.} -type f -name "*.sh") --external-sources
            install -dm755 $out
          '';
          shellspec = pkgs.runCommand "check-shellspec" { } ''
            set -x
            for shell in ${pkgs.ksh}/bin/ksh ${pkgs.oksh}/bin/ksh ${pkgs.zsh}/bin/zsh ${pkgs.bash}/bin/bash; do
              ${pkgs.python3}/bin/python3 -c 'import pty; pty.spawn("${pkgs.shellspec}/bin/shellspec -c ${./.} --shell \$shell -x")'
            done
            install -dm755 $out
          '';
        };
      }
      );
}
