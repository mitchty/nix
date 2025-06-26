{
  description = "my nix flake configuration rewrite (partier deux en flakelight)";

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
          # Ensure the dns blocklist package is working
          dns = pkgs: pkgs.dns-blocklists;
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
      # "I'll fix it in post"
      # just want to be sure I can use deploy-rs to deploy a system profile and a homeconfiguration
      deploy = {
        sshUser = "root";
        user = "root";
        autoRollback = true;
        magicRollback = true;

        nodes = {
          "plx" = {
            hostname = "plx.home.arpa";
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations."plx";
            };
            # profiles.mitch = {
            #   sshUser = "mitch";
            #   user = "mitch";
            #   profilePath = "/nix/var/nix/profiles/per-user/mitch/home-manager";
            #   path = inputs.deploy-rs.lib.x86_64-linux.activate.home-manager inputs.self.homeConfigurations.mitch;
            # };
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
    nixpkgs-old.url = "github:NixOS/nixpkgs/nixos-24.11";
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
