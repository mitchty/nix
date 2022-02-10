{
  description = "mitchty nixos flake setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    master.url = "github:NixOS/nixpkgs/master";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # wip
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
    sops = {
      url = "github:Mic92/sops-nix";
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
    , emacs-overlay
    , home-manager
    , nixos-generators
    , deploy-rs
    , sops
    , ...
    }:
    let
      inherit (nix-darwin.lib) darwinSystem;
      inherit (inputs.unstable.lib) attrValues makeOverridable optionalAttrs singleton nixosSystem mkIf;
      inherit (inputs.unstable.stdenv) isLinux;

      nixpkgsConfig = {
        # overlays = attrValues self.overlays ++ [
        #   emacs-overlay.overlay
        # ];
        overlays = [
          emacs-overlay.overlay
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
            sops.defaultSopsFile = ./secrets/passwd.yaml;
            sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            sops.secrets."users/root" = { };
            sops.secrets."users/mitch" = { };

            nixpkgs = nixpkgsConfig;
            users.users.${primaryUser}.home = "/home/${primaryUser}";
            home-manager.useGlobalPkgs = true;
            home-manager.users.${primaryUser} = homeManagerCommonConfig;
            nix.registry.my.flake = self;
          }
        )
      ];

      dfs1Autoinstall = {
        autoinstall.hostName = "dfs1";
        autoinstall.dedicatedBoot = "/dev/disk/by-id/ata-Hoodisk_SSD_J7TTC7A11230120";
        autoinstall.rootDevices = [
          "/dev/disk/by-id/ata-Samsung_Portable_SSD_T5_S4B0NR0RA00895L"
          "/dev/disk/by-id/ata-Samsung_Portable_SSD_T5_S4B0NR0RA01770E"
        ];
      };
    in
    {
      install-sd = nixos-generators.nixosGenerate {
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        format = "sd-aarch64";
      };
      iso = nixos-generators.nixosGenerate {
        pkgs = unstable.legacyPackages.x86_64-linux;
        format = "iso";
      };
      install-iso = nixos-generators.nixosGenerate {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        format = "install-iso";
      };
      # install-vbox = nixos-generators.nixosGenerate {
      #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
      #   format = "virtualbox";
      # };
      # install-vagrant = nixos-generators.nixosGenerate {
      #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
      #   format = "vagrant";
      # };
      # install-vmware = nixos-generators.nixosGenerate {
      #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
      #   format = "vmware";
      # };
      # install-lxc = nixos-generators.nixosGenerate {
      #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
      #   format = "lxc";
      # };

      # test = nixos-generators.nixosGenerate {
      #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
      #   format = "install-iso";
      #   modules = [
      #     ./iso/configuration.nix { inherit hostname; }
      #   ];
      # };
      # Ok so building specific autoinstall iso's
      #
      # First one here is for the nuc which has two nvme drives. Note, I'm
      # using by-id links for installation to ensure the layout is exactly as
      # desired.
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
        isoDfs1 = nixos-generators.nixosGenerate {
          pkgs = unstable.legacyPackages.x86_64-linux;
          modules = [
            ./iso/autoinstall.nix
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
            ./iso/autoinstall.nix
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
            hostname = "10.10.10.190";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."dfs1";
            };
          };
          # TODO: Fails grub install for some reason, probably just need to rebuild the stupid thing
          # [deploy] [INFO] Activating profile `system` for node `slaptop`
          # [activate] [INFO] Activating profile
          # updating GRUB 2 menu...
          # installing the GRUB 2 boot loader on /dev/disk/by-uuid/5996-2431...
          # Installing for i386-pc platform.
          # /nix/store/k337pspx293idb80340jhkyfvxfq21q8-grub-2.06/sbin/grub-install: warning: File system `fat' doesn't support embedding.
          # /nix/store/k337pspx293idb80340jhkyfvxfq21q8-grub-2.06/sbin/grub-install: warning: Embedding is not possible.  GRUB can only be installed in this setup by using blocklists.  However, blocklists are UNRELIABLE and their use is discouraged..
          # /nix/store/k337pspx293idb80340jhkyfvxfq21q8-grub-2.06/sbin/grub-install: error: will not proceed with blocklists.
          # /nix/store/mdafvgivvfw45hnw3vnch0006x90aa0q-install-grub.pl: installation of GRUB on /dev/disk/by-uuid/5996-2431 failed: Inappropriate ioctl for device
          # "slaptop" = {
          #   hostname = "10.10.10.207";
          #   profiles.system = {
          #     path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."slaptop";
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
