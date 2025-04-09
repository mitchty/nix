pkgs: with pkgs; {
  # TODO: most of these really should be a check somehow
  #
  # For now I'm just including them in the devshell so I can test local pacakge
  # derivations.
  packages = [
    #    yt-dlp-wrapped
    altshfmt
    coreutils
    curl
    home-manager
    htmlq
    hwatch
    jq
    nix-update
    nixfmt-rfc-style
    nixos-generate
    qemu-uefi-wrapper
    statix
    treefmt
    ytdl-sub
  ];
}
