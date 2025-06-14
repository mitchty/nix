{ stdenv, lib, ... }:
{
  # TODO: most of these really should be a check somehow
  #
  # For now I'm just including them in the devshell so I can test local pacakge
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
      git
      git-agecrypt
      home-manager
      htmlq
      jq
      nix-update
      nixfmt-rfc-style
      nixos-generate
      open-webui-cli
      ripgrep
      statix
      treefmt
      yq-go
    ]
    # Only need these on linux or they don't build on macos...
    ++ lib.optionals stdenv.isLinux [
      puppeteer-cli
      poppler_utils
      qemu-uefi-wrapper
    ];
}
