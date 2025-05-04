{
  description = "my nix flakelight configuration rewrite... attempt (partier deux)";

  outputs =
    {
      flakelight,
      flakelight-darwin,
      nixpkgs,
      ...
    }@inputs:
    flakelight ./. (
      { lib, stdenv, ... }:
      {
        inherit inputs;
        # All here and not in ./nix cause I don't feel like figuring out how to
        imports = [ flakelight-darwin.flakelightModules.default ];

        # Without this ^^^ sets systems to just aarch64-darwin and x86_64-darwin
        systems = lib.mkForce [
          "x86_64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];

        withOverlays = [
          (final: prev: {
            # Exposes each input as pkgs.name in the normal package set
            #
            # Not quite an "overlay" but a way to abuse different package inputs
            # or use all of em if I want in my own derivations.
            unstable = import inputs.unstable {
              inherit (prev) system;
              config = {
                allowUnfree = true;
              };
            };
            # workaround for macos
            # https://github.com/NixOS/nixpkgs/issues/402079#issuecomment-2846520987
            # for bash-language-server/yaml-language-server ultimately, mabye I
            # skip it for a while till the fix gets into 24.11
            nodejs = prev.nodejs_22;
            nodejs-slim = prev.nodejs-slim_22;
            open-webui-cli = inputs.open-webui-cli.packages.${prev.system}.release;
            inherit (inputs.nix-update.packages.${prev.system}) nix-update;
            inherit (inputs.nixos-generators.packages.${prev.system}) nixos-generate;
            inherit (inputs.home-manager.packages.${prev.system}) home-manager;
          })
          inputs.emacs-overlay.overlay
          inputs.deploy-rs.overlay
          inputs.agenix.overlays.default
          inputs.fenix.overlays.default
          inputs.nur.overlays.default
          inputs.self.overlays.overrides
          inputs.self.overlays.emacs
          inputs.self.overlays.yt-dlp
        ];

        checks = {
          altshfmt = pkgs: pkgs.altshfmt;
          openwebui = pkgs: pkgs.open-webui;
          # Make sure yt stuff builds at least (its got its own unit tests in the
          # derivation we're testing against nixpkgs so no need for further checks
          # here... yet?)
          ytdlSub = pkgs: pkgs.ytdl-sub;
          ytDlp = pkgs: pkgs.yt-dlp;
          ytdlpgetpot = pkgs: pkgs.yt-dlp-get-pot;
          # Ensure the dns blocklist package is working
          dns = pkgs: pkgs.dns-blocklists;
          # Make sure this beast builds at least
          myEmacs = pkgs: pkgs.myEmacs;
          myWrappedEmacs = pkgs: pkgs.wrappedEmacs;
          # TODO: double check this check in disko is right, seems wrong
          #wtf = inputs.nixpkgs.lib.versionAtLeast inputs.nixpkgs.lib.version "24.11.20240709";
          statix = pkgs: "${pkgs.statix}/bin/statix check";
        };

        formatters = pkgs: {
          "*.sh" = "${pkgs.shfmt}/bin/shfmt -w .";
        };
        legacyPackages = pkgs: pkgs;
        formatter = pkgs: pkgs.nixfmt-rfc-style;
      }
    );

  nixConfig.commit-lockfile-summary = "flake: Update inputs";

  # Just inputs after here. TODO: some of these might be derivations in disguise
  # future mitch figure it out. The dns blocklist is definitely in this category.
  inputs = {
    # Release YY.MM branch name stuff kept close together for lazy.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-release.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # TODO: do I really need this?
    #    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs-release";
    };
    flakelight-darwin = {
      url = "github:cmacrae/flakelight-darwin";
      inputs = {
        flakelight.follows = "flakelight";
        nix-darwin.follows = "nix-darwin";
      };
    };
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flakelight = {
      url = "github:nix-community/flakelight";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flakelight-elisp = {
      url = "github:accelbread/flakelight-elisp";
      inputs.flakelight.follows = "flakelight";
    };
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
    open-webui-cli = {
      url = "github:mitchty/open-webui-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
