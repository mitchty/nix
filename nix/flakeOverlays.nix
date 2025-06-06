{ inputs, ... }:
[
  (final: prev: {
    # Exposes each input as pkgs.name in the normal package set
    #
    # Not quite an "overlay" but a way to abuse different package inputs
    # or use all of em if I want in derivations here.
    unstable = import inputs.nixpkgs-unstable {
      inherit (prev) system;
      config.allowUnfree = true;
      config.allowBroken = true; # darwin/aarch64 OVMF marked broken
    };
    # TODO: Should I even keep this here? Also nix-hardware needs to get
    # in here at some point.
    open-webui-cli = inputs.open-webui-cli.packages.${prev.system}.release;
    inherit (inputs.nix-update.packages.${prev.system}) nix-update;
    inherit (inputs.nixos-generators.packages.${prev.system}) nixos-generate;
    inherit (inputs.home-manager.packages.${prev.system}) home-manager;
    # workaround for macos
    # https://github.com/NixOS/nixpkgs/issues/402079#issuecomment-2846520987
    # for bash-language-server/yaml-language-server ultimately, mabye I
    # skip it for a while till the fix gets into 24.11
    nodejs = prev.nodejs_22;
    nodejs-slim = prev.nodejs-slim_22;
  })
  inputs.emacs-overlay.overlay
  inputs.deploy-rs.overlays.default
  inputs.agenix.overlays.default
  inputs.fenix.overlays.default
  inputs.nur.overlays.default
  inputs.self.overlays.overrides
  inputs.self.overlays.emacs
  inputs.self.overlays.yt-dlp
]
