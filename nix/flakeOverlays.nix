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
    cf-dns-update = inputs.cf-dns-update.packages.${prev.system}.default;
    kairos = inputs.kairos.packages.${prev.system}.default;
    open-webui-cli = inputs.open-webui-cli.packages.${prev.system}.release;
    inherit (inputs.nix-update.packages.${prev.system}) nix-update;
    inherit (inputs.nixos-generators.packages.${prev.system}) nixos-generate;
    inherit (inputs.home-manager.packages.${prev.system}) home-manager;
  })
  inputs.emacs-overlay.overlay
  inputs.deploy-rs.overlays.default
  inputs.agenix.overlays.default
  inputs.fenix.overlays.default
  inputs.nur.overlays.default
]
++ (with inputs.self.overlays; [
  overrides
  emacs
  yt-dlp
])
