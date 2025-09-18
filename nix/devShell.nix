{
  stdenv,
  lib,
  inputs,
  system,
  ...
}:
{
  # TODO: most of these really should be a check somehow
  #
  # For now I'm just including them in the devshell so I can test local package
  # derivations.
  packages =
    pkgs:
    with pkgs;
    [
      agenix
      altshfmt
      cf-dns-update
      coreutils
      curl
      home-manager
      htmlq
      jq
      nix-update
      nixfmt-rfc-style
      nixos-generate
      ripgrep
      statix
      treefmt
      yq-go
      omnix-cli
      vim
      wireguard-tools
      # TODO: deploy-rs no worky here, why? Future mitch problem
    ]
    ++ [
      inputs.deploy-rs.packages.${system}.deploy-rs
    ]
    # Only need these on linux or they don't build on macos...
    ++ lib.optionals stdenv.isLinux [
      puppeteer-cli
      poppler_utils
      qemu-uefi-wrapper
      rust-analyzer-nightly
    ];
}
