{
  description = "my nix flake postantepenultimate configuration (this is the last rewrite honest yeah I don't buy it either)";

  outputs =
    {
      flakelight,
      ...
    }@inputs:
    flakelight ./. (
      # TODO: add https://github.com/serokell/deploy-rs to the
      # nixosConfigurations to validate that setup.
      {
        lib,
        stdenv,
        pkgs,
        moduleArgs,
        ...
      }:
      let
        mylib = import ./nix/lib.nix { inherit lib; };
      in
      {
        nixpkgs.config = {
          allowUnfree = true;
        };
        inherit inputs;
        # All here and not in ./nix cause I don't feel like doing it better,
        # future mitch problem.
        imports = [
          inputs.flakelight-darwin.flakelightModules.default
          inputs.flakelight-crossplatform.flakelightModules.default
        ];

        # Without this ^^^ sets systems to just aarch64-darwin and x86_64-darwin
        systems = lib.mkForce [
          "x86_64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];

        # Layer in my overlay changes to upstream
        withOverlays = import ./nix/flakeOverlays.nix moduleArgs;

        # TODO need to convert things here over to nix tests
        checks =
          pkgs:
          {
            statix = "${pkgs.statix}/bin/statix check";
          }
          # Automatically generate build checks for all packages in nix/packages
          // mylib.mkPackageChecks ./nix/packages pkgs;

        formatters = import ./nix/flakeFormatters.nix;

        legacyPackages = pkgs: pkgs;
        formatter = pkgs: pkgs.nixfmt-rfc-style;

        # Handles the work of wrapping nix flake check for me on macos and
        # undoing that too on linux if I run things.
        # nix run .#check && nix flake check -L ... now instead of nix flake check -L
        apps = {
          check = mylib.mkShellApp "check" ''
            hack=hacks/flake-check.nix
            git checkout $hack
            if [ "$(uname -s)" != "Linux" ]; then
              echo false > $hack
            fi
          '';
          # quick app script to just update the nix flake firewall related input deps
          update-fw = mylib.mkShellApp "update-fw" ''
            nix flake update dns geo
          '';
          # Update only deps that emacs derivations use
          update-emacs = mylib.mkShellApp "update-emacs" ''
            nix flake update eca emacs-overlay
          '';
          build-nixos = mylib.mkShellApp "build-nixos" ''
            for host in plx ark wm2 gw0 rtx; do
              nix build .#nixosConfigurations.$host.config.system.build.toplevel &
            done
            wait
          '';
        };
      }
    )
    // {
      # THIS IS ALL A TEMPORARY TEST
      # "I'll fix it in post" TM C R (I probably won't anytime soon before winter)
      deploy = {
        sshUser = "root";
        user = "root";
        autoRollback = true;
        magicRollback = true;

        nodes = {
          "gw0" = {
            hostname = "gw0.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations."gw0";
            };
          };
          "plx" = {
            hostname = "plx.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations."plx";
            };
          };
          "rtx" = {
            hostname = "rtx.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations."rtx";
            };
          };
          "ark" = {
            hostname = "ark.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations."ark";
            };
          };
          "wm2" = {
            hostname = "wm2.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations."wm2";
            };
          };
          "tmp" = {
            hostname = "tmp.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations."tmp";
            };
          };
          "vm-simple" = {
            sshUser = "mitch";
            hostname = "127.0.0.1";
            sshOpts = [
              "-p"
              "14522"
              "-q"
              "-o"
              "UserKnownHostsFile=/dev/null"
              "-o"
              "StrictHostKeyChecking=no"
            ];
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations."vm-simple";
            };
          };
          "vm-mirror" = {
            hostname = "127.0.0.1";
            sshOpts = [
              "-p"
              "6622"
              "-q"
              "-o"
              "UserKnownHostsFile=/dev/null"
              "-o"
              "StrictHostKeyChecking=no"
            ];
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations."vm-mirror";
            };
          };
        };
      };
    };

  nixConfig.commit-lockfile-summary = "flake: Update inputs";

  # Just inputs after here. TODO: some of these might be derivations in disguise
  # future mitch figure it out. The dns blocklist is definitely in this category.
  inputs = {
    # Release YY.MM branch name stuff kept close together for lazy.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # If/when open-webui breaks... again let me pin just that junk to last
    # working version until fixed.
    #    nixpkgs-ai.url = "github:NixOS/nixpkgs/bce5fe2bb998488d8e7e7856315f90496723793c";
    nixpkgs-ai.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flakelight-darwin = {
      # Until pr is merged use this guys fork with flakelight main branch attr fix
      # ref: https://github.com/cmacrae/flakelight-darwin/pull/1
      url = "github:gkze/flakelight-darwin";
      inputs = {
        flakelight.follows = "flakelight";
        nix-darwin.follows = "nix-darwin";
      };
    };
    flakelight-crossplatform = {
      # Until pr is merged use my fork with flakelight main branch attr fix
      url = "github:mitchty/flakelight-crossplatform";
      #      url = "github:rencire/flakelight-crossplatform";
      # url = "path:/Users/mitch/src/pub/github.com/mitchty/flakelight-crossplatform";
      inputs.flakelight.follows = "flakelight";
    };
    flakelight = {
      url = "github:nix-community/flakelight";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko = {
      url = "github:nix-community/disko";
      #url = "path:/home/mitch/src/pub/github.com/nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-update = {
      url = "github:MiC92/nix-update";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-analyzer-src.follows = "";
    };
    agenix.url = "github:ryantm/agenix";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    omnix.url = "github:juspay/omnix";
    nix-sweep.url = "github:jzbor/nix-sweep";
    nixpkgs-eca.url = "github:NixOS/nixpkgs/8913c168d1c56dc49a7718685968f38752171c3b";
    eca = {
      url = "github:editor-code-assistant/eca";
      inputs.nixpkgs.follows = "nixpkgs-eca";
    };
    cf-dns-update = {
      url = "github:mitchty/cf-dns-update";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    open-webui-cli = {
      url = "github:mitchty/open-webui-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kairos = {
      url = "github:mitchty/kairos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # IP CIDR lists for nftable rule sets
    geo = {
      url = "github:ipverse/rir-ip";
      flake = false;
    };
    # Dns blocklist data
    dns = {
      url = "github:hagezi/dns-blocklists";
      flake = false;
    };
  };
}
