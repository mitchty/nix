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
    ]
    # Only need these on linux
    ++ lib.optionals stdenv.isLinux [
      qemu-uefi-wrapper
    ];
}
