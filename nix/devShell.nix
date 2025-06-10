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
      altshfmt
      cf-dns-update
      open-webui-cli
      coreutils
      curl
      git
      home-manager
      htmlq
      jq
      nix-update
      nixfmt-rfc-style
      ripgrep
      statix
      treefmt
      nixos-generate
      agenix
      git-agecrypt
      #      ytdl-sub-with-plugins
    ]
    # Only need these on linux or they don't build on macos...
    ++ lib.optionals stdenv.isLinux [
      puppeteer-cli
      poppler_utils
      qemu-uefi-wrapper
    ];
}
