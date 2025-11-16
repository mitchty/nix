{
  description = "my nix flake postantepenultimate configuration (this is the last rewrite honest yeah I don't buy it either)";

  # This all gets prompted and crap at nix develop or with direnv+.envrc when you cd into the dir... I like it but... its a pita
  # TODO: future sucker mitch see if there is another option?
  # nixConfig = {
  #   extra-experimental-features = "nix-command flakes";
  #   extra-substituters = [
  #     "https://cache.nixos.org/"
  #     "https://nix-community.cachix.org"
  #     "https://deploy-rs.cachix.org"
  #   ];
  #   extra-trusted-public-keys = [
  #     "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  #     "deploy-rs.cachix.org-1:xfNobmiwF/vzvK1gpfediPwpdIP0rpDV2rYqx40zdSI="
  #   ];
  # };

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
        checks = {
          altshfmt = pkgs: pkgs.altshfmt;
          # Make sure yt stuff builds at least (its got its own unit tests in the
          # derivation we're testing against nixpkgs so no need for further checks
          # here... yet?)
          ytdlSub = pkgs: pkgs.ytdl-sub;
          ytdlSubPlugins = pkgs: pkgs.ytdl-sub-with-plugins;
          ytDlp = pkgs: pkgs.yt-dlp;
          ytDlpPlugins = pkgs: pkgs.yt-dlp-with-plugins;
          ytdlpgetpot = pkgs: pkgs.yt-dlp-get-pot;
          # Make sure this beast builds at least
          #myEmacs = pkgs: pkgs.myEmacs;
          # TODO: need to get this stupid version working with default builtin
          # tools wrapped inside as well. That way I can lighten the development
          # module.
          myWrappedEmacs = pkgs: pkgs.wrappedEmacs;
          statix = pkgs: "${pkgs.statix}/bin/statix check";
          # }
          # # TODO: how this isn't working is beyond me for now wgaf I'm not using it yet future me problem.
          # // lib.optionalAttrs lib.stdenv.hostPlatform.isLinux {
          #   # Make sure my overlay for this thing works but only on linux
          #   openwebui = pkgs: pkgs.open-webui;
        };

        formatters = import ./nix/flakeFormatters.nix;

        legacyPackages = pkgs: pkgs;
        formatter = pkgs: pkgs.nixfmt-rfc-style;

        # Handles the work of wrapping nix flake check for me on macos and
        # undoing that too on linux if I run things.
        # nix run .#check && nix flake check -L ... now instead of nix flake check -L
        apps = {
          check = pkgs: {
            type = "app";
            program = "${
              pkgs.writeShellApplication {
                name = "check";
                text = ''
                  set -e
                  hack=hacks/flake-check.nix
                  git checkout $hack
                  if [ "$(uname -s)" != "Linux" ]; then
                    echo false > $hack
                  fi
                '';
              }
            }/bin/check";
          };
          # quick app script to just update the nix flake firewall related input deps
          update-fw = pkgs: {
            type = "app";
            program = "${
              pkgs.writeShellApplication {
                name = "update-fw";
                text = ''
                  set -e
                  nix flake update dns geo
                '';
              }
            }/bin/update-fw";
          };
          # Update only deps that emacs derivations use
          update-emacs = pkgs: {
            type = "app";
            program = "${
              pkgs.writeShellApplication {
                name = "update-emacs";
                text = ''
                  set -e
                  nix flake update eca emacs-overlay
                '';
              }
            }/bin/update-emacs";
          };
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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Get yt-dlp working again with a cheap hack
    # TODO: https://github.com/NixOS/nixpkgs/pull/460892/files
    tmpyt.url = "github:Mynacol/nixpkgs/yt-dlp-js";

    # If/when open-webui breaks... again let me pin just that junk to last
    # working version until fixed.
    #    nixpkgs-ai.url = "github:NixOS/nixpkgs/bce5fe2bb998488d8e7e7856315f90496723793c";
    nixpkgs-ai.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # TODO: do I really need this anymore? here for future me to uncomment if I
    # do.
    #    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
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
    omnix = {
      url = "github:juspay/omnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # TESTING
    nix-sweep = {
      url = "github:jzbor/nix-sweep";
      #      inputs.nixpkgs.follows = "nixpkgs";
    };
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
