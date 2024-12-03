{
  description = "mitchty flake setup";

  inputs = {
    # This is evil but I'm sick of commenting things out
    #
    # The premise is this is the "default" and if I want to do a build
    # without it I pass it in as an arg.
    # like so nix build --override-input with-homecache github:boolean-option/false
    with-homecache.url = "github:boolean-option/true";

    # this is to let me set the host used for deploy-rs to localhost
    # instead of having 2x definitions for each.
    with-localhost.url = "github:boolean-option/true";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Splicing this into where I needs it.
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    #    master.url = "github:NixOS/nixpkgs/master";

    # Currently mostly abusing this for open-webui nixos module+pkg
    master.url = "github:NixOS/nixpkgs/551c0f1ec4efe400c70f33b57c6e8caf23a04b97";

    # Ignore whatever I used for inputs.nixpkgs to save on extraneous
    # derivations.
    mitchty = {
      url = "github:mitchty/nixos";
      #      inputs.nixpkgs.follows = "nixpkgs"; TODO hwatch fails to build with 1.74 rustc fix later
    };
    # mitchty.url = "path:/Users/mitch/src/pub/github.com/mitchty/nixos";
    # mitchty.url = "path:/Users/tishmack/src/pub/github.com/mitchty/nixos";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-pacemaker.url = "github:mitchty/nixpkgs/corosync-pacemaker-ocf";
    # nixpkgs-pacemaker.url = "path:/Users/mitch/src/pub/github.com/mitchty/nixpkgs@pacemaker";

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
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
      #      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dnsblacklist = {
      url = "github:hagezi/dns-blocklists";
      flake = false;
    };

    # These have no nixpkgs inputs nothing to override
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nur.url = "github:nix-community/NUR";

    # nixinit.url = "github:nix-community/nix-init";
    otest.url = "github:mitchty/nix/refactor";

    ollama = {
      url = "github:mastoca/ollama-flake";
      inputs.nixpkgs.follows = "unstable";
    };

  };

  outputs =
    inputs@{ self
    , ...
    }:
    let
      inherit (inputs.darwin.lib) darwinSystem;
      inherit (inputs.nixpkgs.lib) attrValues makeOverridable nixosSystem writeScriptBin;

      x86-linux = "x86_64-linux";

      homeDir = system: user: with inputs.nixpkgs.legacyPackages.${system}.stdenv;
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
        inputs.emacs-overlay.overlay
        inputs.rust.overlays.default
        inputs.rust.overlays.rust-overlay
        inputs.nur.overlay
        #        inputs.mitchty.overlays.default
      ] ++ myOverlays ++ [
        # Splice in unstable pkgs into pkgs to be abused as pkgs.unstable.NAME
        (final: prev: {
          unstable = import inputs.unstable {
            system = prev.system;
            config = {
              allowUnfree = true;
            };
          };
        })
        # and master (this ones touchy af master barely builds lol)
        (final: prev: {
          master = import inputs.master {
            system = prev.system;
            config = {
              allowUnfree = true;
            };
          };
        })
        (final: prev: {
          agenix = import inputs.agenix.packages {
            system = prev.system;
          };
        })
        # And do similar for my stuff until I get time to make it an overlay of its own
        (final: prev: {
          mitchty = import inputs.mitchty.packages {
            system = prev.system;
          };
        })
        (final: prev: {
          ollama = import inputs.ollama.packages {
            system = prev.system;
          };
        })
        # Note these come after ^^^ as they use some things those overlays define
        # TODO: this stuff should all get put into a flake overlay in this repo
        # stop being lazy, just not sure how to pass in the custom pacemaker
        # nixpkgs to do it.
        (
          # force in the ocf-resource-agents/pacemaker I patched into nixpkgs-pacemaker
          # ignore system as for now all it runs on is x86_64-linux so
          # whatever
          final: prev: rec {
            pacemaker = inputs.nixpkgs-pacemaker.legacyPackages.x86_64-linux.pacemaker;
            ocf-resource-agents = inputs.nixpkgs-pacemaker.legacyPackages.x86_64-linux.ocf-resource-agents;
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
        config = {
          #          permittedInsecurePackages = [ "python3.10-django-3.1.14" ];
          allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [
            "cuda-merged"
            "nvidia-x11"
          ];
          allowUnfree = true;
          allowCuda = true;
        };
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
        inputs.home-manager.darwinModules.home-manager
        ./modules/darwin
        ./modules/roles/gui.nix
        ./modules/roles/gui-new.nix
        #      ] ++ myRoles ++ [
        inputs.agenix.darwinModules.age
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
              inherit inputs;
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
        inputs.home-manager.nixosModules.home-manager
        inputs.nur.nixosModules.nur
        ./modules/nixos
        #      ] ++ myRoles ++ [
        (import ./modules/roles/gui.nix)
        inputs.agenix.nixosModules.age
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
              inherit inputs;
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
            "/dev/disk/by-id/nvme-Sabrent_Rocket_Q4_48821081708402"
            "/dev/disk/by-id/nvme-CWESR02TBTLCZ-27J-2_511231016041001198"
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

      cifsSecrets = {
        "cifs/plex" = {
          file = ./secrets/cifs/plex.age;
        };
        "cifs/mitch" = {
          file = ./secrets/cifs/mitch.age;
        };
      };

      # Make age.secrets = a bit simpler with some defined variables
      homeUser = "mitch";
      homeGroup = "users";

      workUser = "tishmack";
      rootUser = "root";

      ageDefault = user: canarySecret user;
      ageGit = user: gitSecret user // ghcliPubSecret user;

      ageHome = user: ageDefault user // ageGit user;
      ageHomeWithBackup = user: ageHome user;
      ageHomeNixos = user: ageHome user // passwdSecrets;
      ageHomeNixosWithBackup = user: ageHomeNixos user;

      ageCifsNixos = cifsSecrets;

      # Simple wrapper function to save on some redundancy for being lay zee
      withLocalhost = host: if inputs.with-localhost.value then "localhost" else host;
    in
    {
      packages.x86_64-linux = {
        isoSimple = inputs.nixos-generators.nixosGenerate {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            simpleAutoinstall
            {
              autoinstall.debug = true;
            }
          ];
          format = "install-iso";
        };
        isoSimpleTest = inputs.nixos-generators.nixosGenerate {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            simpleAutoinstall
            {
              autoinstall.debug = true;
            }
          ];
          format = "install-iso";
        };
        isoZfsTest = inputs.nixos-generators.nixosGenerate {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            zfsAutoinstall
            {
              autoinstall.debug = true;
            }
          ];
          format = "install-iso";
        };
        isoWm2 = inputs.nixos-generators.nixosGenerate {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
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
        isoCl1 = inputs.nixos-generators.nixosGenerate {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
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
            latest = inputs.latest.legacyPackages.${x86-linux};
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
            latest = inputs.latest.legacyPackages.${x86-linux};
          };
        };
        wm2 =
          (makeOverridable nixosSystem)
            rec {
              system = "x86_64-linux";
              modules = nixOSModules ++ [
                ./hosts/wm2/configuration.nix
                inputs.nixos-hardware.nixosModules.common-cpu-amd
                # inputs.nixos-hardware.nixosModules.common-gpu-amd
                inputs.nixos-hardware.nixosModules.common-pc-laptop
                inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
                inputs.nixos-hardware.nixosModules.gpd-win-max-2-2023
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
                latest = inputs.latest.legacyPackages.${x86-linux};
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
              latest = inputs.latest.legacyPackages.${x86-linux};
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
              latest = inputs.latest.legacyPackages.${x86-linux};
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
              latest = inputs.latest.legacyPackages.${x86-linux};
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
              latest = inputs.latest.legacyPackages.${x86-linux};
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
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."simple";
            };
          };
          "gw" = {
            hostname = "gw.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."gw";
            };
          };
          "srv" = {
            hostname = withLocalhost "srv.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."srv";
            };
          };
          "local-srv" = {
            hostname = "127.0.0.1";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."srv";
            };
          };
          "nexus" = {
            hostname = "nexus.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."nexus";
            };
          };
          "wm2" = {
            hostname = withLocalhost "10.10.10.115";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."wm2";
            };
          };
          "cl1" = {
            hostname = "cl1.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."cl1";
            };
          };
          "cl2" = {
            hostname = "cl2.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."cl2";
            };
          };
          "cl3" = {
            hostname = "cl3.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."cl3";
            };
          };
          "dfs1" = {
            hostname = "dfs1.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."dfs1";
            };
          };
          "local-mb" = {
            hostname = "localhost";
            profiles.system = {
              sshUser = "mitch";
              sudo = "sudo -S -u";
              path = inputs.deploy-rs.lib.x86_64-darwin.activate.darwin self.darwinConfigurations."mb";
            };
          };
        };
      };

      checks.deploy-rs = builtins.mapAttrs
        (deployLib: deployLib.deployChecks self.deploy)
        inputs.deploy-rs.lib;
      # checks.nixpkgs-fmt = nixpkgs.runCommand "check-nix-format" { } ''
      #   ${nixpkgs.legacyPackages.${system}.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}
      #   install -dm755 $out
      # '';
    } // inputs.flake-utils.lib.eachDefaultSystem
      (system:
      # let pkgs = nixpkgsConfig [ ];
      let pkgs = import inputs.nixpkgs { inherit system; };
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
