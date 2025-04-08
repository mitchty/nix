{
  description = "my nix flakelight configuration rewrite... attempt (partier deux)";

  outputs =
    { flakelight, ... }@inputs:
    flakelight ./. {
      inherit inputs;
      # All here and not in ./nix cause I don't feel like figuring out how to
      # deal with inputs being passed in right now.
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
          open-webui-cli = inputs.open-webui-cli.packages.${prev.system}.release;
          inherit (inputs.nix-update.packages.${prev.system}) nix-update;
          inherit (inputs.nixos-generators.packages.${prev.system}) nixos-generate;
        })
        inputs.nixgl.overlays.default
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
        openwebui = pkgs: pkgs.open-webui;
        ytdlp = pkgs: pkgs.yt-dlp;
        #        ytdlp = pkgs: pkgs.yt-dlp-wrapped;
        # Make sure ytdl-sub and yt-dlp overlay builds at least (its got its own
        # unit tests in the derivation we're testing against nixpkgs)
        ytdlSub = pkgs: pkgs.ytdl-sub;
        # Make sure this beast builds at least
        myEmacs = pkgs: pkgs.myEmacs;
        # TODO: double check this check in disko is right, seems wrong
        #wtf = inputs.nixpkgs.lib.versionAtLeast inputs.nixpkgs.lib.version "24.11.20240709";
        statix = pkgs: "${pkgs.statix}/bin/statix check";
      };

      formatters = pkgs: {
        "*.sh" = "${pkgs.shfmt}/bin/shfmt -w .";
      };
      legacyPackages = pkgs: pkgs;
      formatter = pkgs: pkgs.nixfmt-rfc-style;
    };

  nixConfig.commit-lockfile-summary = "flake: Update inputs";

  # Just inputs after here. TODO: some of these might be derivations in disguise
  # future mitch figure it out. The dns blocklist is definitely in this category.
  inputs = {
    # Release YY.MM branch name stuff kept close together for lazy.
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
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
      #      url = "github:nix-community/emacs-overlay";
      url = "github:nix-community/emacs-overlay/87d5e2bbc04a8d2ddff9e1f9e266bf81c3bd45b2";
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
    dnsblacklist = {
      url = "github:hagezi/dns-blocklists";
      flake = false;
    };
    agenix.url = "github:ryantm/agenix";
    open-webui-cli = {
      url = "github:mitchty/open-webui-cli";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
