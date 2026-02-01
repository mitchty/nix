{
  stdenv,
  lib,
  inputs,
  system,
  ...
}:
{
  packages =
    pkgs:
    with pkgs;
    [
      agenix
      altshfmt
      cf-dns-update
      coreutils
      curl
      etcd
      hfdownloader
      home-manager
      htmlq
      jq
      nix-update
      nixfmt-rfc-style
      nixos-generate
      ripgrep
      statix
      taplo
      treefmt
      vim
      wireguard-tools
      yq-go
    ]
    ++ [
      inputs.deploy-rs.packages.${system}.deploy-rs
    ]
    # Only need these on linux or they don't build on macos...
    ++ lib.optionals stdenv.isLinux [
      puppeteer-cli
      poppler-utils
      qemu-uefi-wrapper
    ];
}
