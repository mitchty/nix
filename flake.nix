{
  description = "mitchty nixos flake setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    latest.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mitchty.url = "github:mitchty/nixos";
    # mitchty.url = "path:/Users/mitch/src/pub/github.com/mitchty/nixos";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";
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

    emacs-upstream = {
      url = "github:emacs-mirror/emacs/emacs-29";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
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

    # terraform-old.url = "github:NixOS/nixpkgs/8c909dd2613323a939c90efddd089c88c0536fbf";

    # the nixpkgs it ships doesn't compile bash on darwin from what I can find.
    nixinit = {
      url = "github:nix-community/nix-init";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , latest
    , mitchty
    , darwin
    , home-manager
    , nixos-generators
    , deploy-rs
    , emacs-overlay
    , emacs-upstream
    , rust
    , agenix
    , dnsblacklist
    , flake-utils
    , nixpkgs-pacemaker
      # , terraform-old
    , nixinit
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

      nixpkgsOverlays = [
        emacs-overlay.overlay
        rust.overlays.default
        (
          # force in the ocf-resource-agents/pacemaker I patched into nixpkgs-pacemaker
          # ignore system as for now all it runs on is x86_64-linux so
          # whatever
          final: prev: rec {
            pacemaker = nixpkgs-pacemaker.legacyPackages.x86_64-linux.pacemaker;
            ocf-resource-agents = nixpkgs-pacemaker.legacyPackages.x86_64-linux.ocf-resource-agents;
          }
        )
        (final: prev: {
          emacs29 = prev.emacs-git.overrideAttrs (old: {
            name = "emacs29";
            version = emacs-upstream.shortRev;
            src = emacs-upstream;
          });
          # TODO: figure out a way to import based on this...
          # sys = pkgs.lib.last (pkgs.lib.splitString "-" pkgs.system);
          emacsWithConfig = (prev.emacsWithPackagesFromUsePackage {
            config = ./static/emacs/init.org;
            package = final.emacs29.overrideAttrs (super: {
              # buildInputs = super.buildInputs ++
              #   nixpkgs.lib.attrsets.attrVals [
              #     "Cocoa"
              #     "WebKit"
              #   ]
              #     nixpkgs-darwin.legacyPackages.x86_64-darwin.apple_sdk.frameworks;
              preConfigure = ''
                sed -i -e 's/headerpad_extra=1000/headerpad_extra=2000/' configure.ac
                autoreconf
              '';
              configureFlags = super.configureFlags ++ [
                # "--with-native-comp"
                # "--with-xwidgets"
                "--with-natural-title-bar"
              ];
              patches = [
                # (prev.fetchpatch {
                #   name = "mac-gui-loop-block-lifetime";
                #   url = "https://raw.githubusercontent.com/jwiegley/nix-config/90086414208c3a4dc2f614af5a0dd0c1311f7c6d/overlays/emacs/0001-mac-gui-loop-block-lifetime.patch";
                #   sha256 = "sha256-HqcRxXfZB9LDemkC7ThNfHuSHc5H5B2MQ102ZyifVYM=";
                # })
                # (prev.fetchpatch {
                #   name = "mac-gui-loop-block-autorelease";
                #   url = "https://raw.githubusercontent.com/jwiegley/nix-config/90086414208c3a4dc2f614af5a0dd0c1311f7c6d/overlays/emacs/0002-mac-gui-loop-block-autorelease.patch";
                #   sha256 = "sha256-CBELVTAWwgaXrnkTzMsYH9R18qBnFBFHMOaVeC/F+I8=";
                # })
                (prev.fetchpatch {
                  name = "gc-block-align-patch";
                  url = "https://github.com/tyler-dodge/emacs/commit/36d2a8d5a4f741ae99540e139fff2621bbacfbaa.patch";
                  sha256 = "sha256-/hJa8LIqaAutny6RX/x6a+VNpNET86So9xE8zdh27p8=";
                })
                # (prev.fetchpatch {
                #   name = "buffer-process-output-on-thread-patch";
                #   url = "https://github.com/emacs-mirror/emacs/commit/b386047f311af495963ad6a25ddda128acc1d461.patch";
                #   sha256 = "sha256-dRkiowEtu/oOLh29/b7VSXGKsV5qE0PxMWrox5/LRoM=";
                # })
                # (prev.fetchpatch {
                #   name = "immediate-output-notification-patch";
                #   url = "https://github.com/emacs-mirror/emacs/commit/3f49c824f23b2fa4ce5512f80abdb0888a73c4a1.patch";
                #   sha256 = "sha256-ShQsS9ixc15cyrPGYDLxbbsgySK4JUuCSqk6+XE0U4Q=";
                # })
                ./patches/emacs-use-correct-window-role.patch
              ];
            });
            # Force these two even though they're outside of the org config.
            extraEmacsPackages = epkgs: [
              epkgs.use-package
              epkgs.org
            ];
          });
        })
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
        config.permittedInsecurePackages = [ "garage-0.7.3" ];
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
              age = config.age;
              role = config.role;
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


      pacemakerPath = "services/cluster/pacemaker/default.nix";

      nixOSModules = attrValues
        {
          users = import ./modules/users.nix;
        } ++ [
        home-manager.nixosModules.home-manager
        ./modules/nixos
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
              age = config.age;
            };
            nix.registry.my.flake = self;
          }
        )
      ];

      # Autoinstall vars
      defBootSize = "512MiB";
      defSwapSize = "16GiB";
      smallSwapSize = "512MiB";

      # vm autoinstall test runners, note no by-id links cause qemu doens't get them
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
        isoCl2 = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            cl2Autoinstall
            {
              autoinstall.debug = true;
              autoinstall.wipe = true;
            }
          ];
          format = "install-iso";
        };
        isoCl3 = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/iso/autoinstall.nix
            cl3Autoinstall
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
            services.restic = {
              enable = true;
              repo = "s3:http://dfs1.home.arpa:8333/restic";
            };
            services.home.enable = true;
            services.mitchty.enable = true;
            services.shared.mutagen.enable = true;
            services.shared.syncthing.enable = false;
          }];
        };
        wmb = darwinSystem {
          inherit inputs;
          system = "x86_64-darwin";
          modules = nixDarwinModules ++ [{
            users = {
              primaryUser = workUser;
              primaryGroup = "staff";
            };
            age.secrets = ageHome workUser;
            networking.computerName = "wmb";
            networking.hostName = "wmb";
            networking.knownNetworkServices = [
              "Wi-Fi"
            ];
            services.work.enable = true;
            services.mitchty.enable = true;
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
            services.shared.syncthing = {
              enable = false;
              user = homeUser;
              group = homeGroup;
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
        nexus = (makeOverridable nixosSystem) {
          system = "x86_64-linux";
          modules = nixOSModules ++ [
            ./hosts/nexus/configuration.nix
          ] ++ [{
            users = {
              primaryUser = homeUser;
              primaryGroup = homeGroup;
            };
            age.secrets = ageHomeNixosWithBackup homeUser;
            services.role = {
              gui.enable = true;
              intel.enable = true;
              mosh.enable = true;
              node-exporter.enable = true;
              promtail.enable = true;
            };
            services.shared.syncthing = {
              enable = false;
              user = homeUser;
              group = homeGroup;
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
        cl1 = (makeOverridable nixosSystem) {
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
            };
          }];
          specialArgs = {
            inherit inputs;
            latest = latest.legacyPackages.${x86-linux};
          };
        };
        cl2 = (makeOverridable nixosSystem) {
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
            };
          }];
          specialArgs = {
            inherit inputs;
            latest = latest.legacyPackages.${x86-linux};
          };
        };
        cl3 = (makeOverridable nixosSystem) {
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
          shellcheck = pkgs.runCommand "check-shellcheck" { } ''
            ${pkgs.shellcheck}/bin/shellcheck --severity warning --shell sh $(find ${./.} -type f -name "*.sh") --external-sources
            install -dm755 $out
          '';
          shellspec = pkgs.runCommand "check-shellspec" { } ''
            for shell in ${pkgs.ksh}/bin/ksh ${pkgs.oksh}/bin/ksh ${pkgs.zsh}/bin/zsh ${pkgs.bash}/bin/bash; do
              ${pkgs.python3}/bin/python3 -c 'import pty; pty.spawn("${pkgs.shellspec}/bin/shellspec -c ${./.} --shell \$shell -x")'
            done
            install -dm755 $out
          '';
        };
      }
      );
}
