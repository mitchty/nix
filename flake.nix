{
  description = "mitchty nixos flake setup";

  inputs = {
    # Principle inputs (updated by `nix run .#update`)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-flake.url = "github:srid/nixos-flake";
    # Not overriding inputs.nixpkgs due to
    # https://github.com/nix-community/disko/blob/master/flake.nix#L4
    disko.url = "github:nix-community/disko";

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
    treefmt-nix.url = "github:numtide/treefmt-nix";
    flake-root.url = "github:srid/flake-root";
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      # systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      systems = [ "x86_64-linux" "x86_64-darwin" ];
      imports = [
        inputs.nixos-flake.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.flake-root.flakeModule
        #        inputs.nixos-generators.nixosModules.all-formats
        ./flake/treefmt.nix
      ];

      # inherit (import ./lib/default.nix) mkAutoInstaller;

      perSystem = { config, self', pkgs, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          # overlays = [
          #   inputs.rust-overlay.overlays.default
          # ];
        };

        packages.default = self'.packages.activate;

        formatter = config.treefmt.build.wrapper;

        devShells.default = pkgs.mkShell {
          name = "my-flake"; # TODO: name this something better....
          inputsFrom = [
            #            self'.devShells.rust
            config.treefmt.build.devShell
            config.treefmt.build.programs
            config.treefmt.build.wrapper
          ];
          packages = with pkgs; [
            nixci
          ];
          # shellHook = ''
          #   printf "devshell loaded for all your dev needs" >&2
          # '';
        };
      };

      flake =
        let
          myUserName = "mitch";
          currState = "23.11";
          # fpkgs = inputs.nixpkgs;
          # inherit (fpkgs.lib) attrValues makeOverridable nixosSystem mkForce mkDefault;

          # # For the future...
          # supportedSystems = [
          #   "x86_64-linux"
          # ];

          # forAllSystems = fpkgs.lib.genAttrs supportedSystems;

          # Setup an auto installing iso image using disko
          # mkAutoDiskoIso = fpkgs: nixos-generators.nixosGenerate {
          #   format = "install-iso";
          #   # We always include nixos disko modules for install isos
          #   modules = [

          #   ];
          # };
        in
        {

          # withSystem "x86_64-linux" ({ config, ... }:
          # config.packages.hello
          # )
          # Configurations for Linux (NixOS) machines
          nixosConfigurations = {
            # TODO: Change hostname from "example1" to something else.
            example1 = self.nixos-flake.lib.mkLinuxSystem {
              nixpkgs.hostPlatform = "x86_64-linux";
              imports = [
                self.nixosModules.common # See below for "nixosModules"!
                self.nixosModules.linux
                inputs.disko.nixosModules.default

                # Your machine's configuration.nix goes here
                (_: {
                  # TODO: Put your /etc/nixos/hardware-configuration.nix here
                  boot.loader.grub.device = "nodev";
                  fileSystems."/" = {
                    device = "/dev/disk/by-label/nixos";
                    fsType = "btrfs";
                  };
                  system.stateVersion = currState;
                })
                # Your home-manager configuration
                self.nixosModules.home-manager
                {
                  home-manager.users.${myUserName} = {
                    imports = [
                      self.homeModules.common # See below for "homeModules"!
                      self.homeModules.linux
                    ];
                    home.stateVersion = currState;
                  };
                }
              ];
            };
          };

          # Configurations for macOS machines
          darwinConfigurations = {
            # TODO: Change hostname from "example1" to something else.
            example1 = self.nixos-flake.lib.mkMacosSystem {
              nixpkgs.hostPlatform = "x86_64-darwin";
              imports = [
                self.nixosModules.common # See below for "nixosModules"!
                self.nixosModules.darwin
                # Your machine's configuration.nix goes here
                (_: {
                  # Used for backwards compatibility, please read the changelog before changing.
                  # $ darwin-rebuild changelog
                  system.stateVersion = 4;
                })
                # Your home-manager configuration
                self.darwinModules_.home-manager
                {
                  home-manager.users.${myUserName} = {
                    imports = [
                      self.homeModules.common # See below for "homeModules"!
                      self.homeModules.darwin
                    ];
                    home.stateVersion = currState;
                  };
                }
              ];
            };
          };

          # All nixos/nix-darwin configurations are kept here.
          nixosModules = {
            # Common nixos/nix-darwin configuration shared between Linux and macOS.
            common = { pkgs, ... }: {
              environment.systemPackages = with pkgs; [
                hello
              ];
            };
            # NixOS specific configuration
            linux = _: {
              users.users.${myUserName}.isNormalUser = true;
              services.netdata.enable = true;
            };
            # nix-darwin specific configuration
            darwin = _: {
              security.pam.enableSudoTouchIdAuth = true;
            };
          };

          # All home-manager configurations are kept here.
          homeModules = {
            # Common home-manager configuration shared between Linux and macOS.
            common = _: {
              programs = {
                git.enable = true;
                starship.enable = true;
                bash.enable = true;
              };
            };
            # home-manager config specific to NixOS
            linux = {
              xsession.enable = true;
            };
            # home-manager config specifi to Darwin
            darwin = {
              targets.darwin.search = "Bing";
            };
          };
        };
      # // {
      # # packages = forAllSystems
      # #   (system:
      # #     let
      # #       pkgs = nixpkgs.legacyPackages.${system};
      # #     in
      # #     rec {
      # #       vmZfsMirrorSystem = (makeOverridable nixosSystem) rec {
      # #         inherit system;
      # #         modules = [ ];
      # #         specialArgs = {
      # #           inherit inputs;
      # #         };
      # #       };
      # #       vmZfsMirror = mkAutoDiskoIso pkgs;
      # #       # 2 disk auto mirror setup in disko setup for qemu vm
      # #       # testing/validation (re)uses nixosConfiguration ^^^ for disko
      # #       # install. Note all disko setup is opinionated in that its setup to
      # #       # only use labels or partlabels that lets us create what would be in
      # #       # hardware-configuration.nix ourselves which seems to only include
      # #       # uuid device by default and I want to make that mostly transparent.
      # #       #
      # #       # For now only validating efi bootable stuff out of laziness and
      # #       # need as I can use systemctl reboot --firmware-setup to make it
      # #       # easy to pick disparate devices to test booting off of to manually
      # #       # validate (for now) until at least I can better figure out how to
      # #       # set efi vars to change devices once I figure that out.
      # #       isoZfsTest = mkAutoInstaller vmZfsMirrorSystem;
      # #       default = isoZfsTest;
      # #     });
      # checks = forAllSystems
      #   (system:
      #     let
      #       pkgs = inputs.nixpkgs.legacyPackages.${system};
      #     in
      #     {
      #       # Ensure all our formatting is kosher in nix lande for now.
      #       formatting =
      #         pkgs.writeShellApplication
      #           {
      #             name = "formatting";
      #             runtimeInputs = with pkgs; [
      #               nixpkgs-fmt
      #               deadnix
      #             ];
      #             # TODO: enable deadnix, for now it just wants to remove stuff
      #             # I am working on that I might enable again later
      #             text = ''
      #               nixpkgs-fmt --check "$@"
      #               #            deadnix --edit "$@"
      #             '';
      #           };
      #       shell = pkgs.writeShellApplication
      #         {
      #           name = "shellchecks";
      #           runtimeInputs = with pkgs; [
      #             shellcheck
      #             shellspec
      #             ksh
      #             oksh
      #             zsh
      #             bash
      #             findutils
      #             # abusing python3 for pty support cause shellspec needs it for
      #             # some output or another to run in nix given nix runs top most
      #             # pid without a pty. We could do this any way we can get a pty
      #             # so that shellspec can run but this is fine.
      #             python3
      #           ];
      #           text = ''
      #             shellcheck --severity warning --shell sh "$(find ${./.} -type f -name '*.sh')" --external-sources
      #             for shell in ${pkgs.ksh}/bin/ksh ${pkgs.oksh}/bin/ksh ${pkgs.zsh}/bin/zsh ${pkgs.bash}/bin/bash; do
      #                                   ${pkgs.python3}/bin/python3 -c 'import pty; pty.spawn("${pkgs.shellspec}/bin/shellspec -c ${./.} --shell '$shell' -x")'
      #                                 done
      #           '';
      #           # deploy-rs =
      #           #   builtins.mapAttrs
      #           #     (deployLib: deployLib.deployChecks self.deploy)
      #           #     deploy-rs.lib;
      #         };
      #     }
      #        );
      # };
    };
}
