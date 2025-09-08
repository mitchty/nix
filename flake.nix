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

        withOverlays = import ./nix/flakeOverlays.nix moduleArgs;

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
          myEmacs = pkgs: pkgs.myEmacs;
          # TODO: need to get this stupid version working with default builtin
          # tools wrapped inside as well. That way I can lighten the development
          # module.
          myWrappedEmacs = pkgs: pkgs.wrappedEmacs;
          # TODO: double check this check in disko is right, seems wrong
          #wtf = inputs.nixpkgs.lib.versionAtLeast inputs.nixpkgs.lib.version "24.11.20240709";
          # My paid font derivation (note this WILL fail for anyone that doesn't
          # have the encryption key so... your problem not mine buy the fonts
          # don't be stingy support font makers)
          myFonts = pkgs: pkgs.paid-fonts;
          statix = pkgs: "${pkgs.statix}/bin/statix check";
          # }
          # # TODO: how this isn't working is beyond me for now wgaf I'm not using it yet future me problem.
          # // lib.optionalAttrs lib.stdenv.hostPlatform.isLinux {
          #   # Make sure my overlay for this thing works but only on linux
          #   openwebui = pkgs: pkgs.open-webui;
        };

        formatters = pkgs: {
          "*.sh" = "${pkgs.shfmt}/bin/shfmt -w .";
        };
        legacyPackages = pkgs: pkgs;
        formatter = pkgs: pkgs.nixfmt-rfc-style;
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
          "ark" = {
            hostname = "ark.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations."ark";
            };
          };
          "vm-simple" = {
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
    # Don't need this anymore.
    #nixpkgs-old.url = "github:NixOS/nixpkgs/nixos-24.11";

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
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-analyzer-src.follows = "";
    };
    agenix.url = "github:ryantm/agenix";
    #agenix.url = "/Users/mitch/src/pub/github.com/ryantm/agenix";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };
}
