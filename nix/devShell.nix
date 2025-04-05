pkgs: with pkgs; {
  # TODO: most of these really should be a check somehow
  #
  # For now I'm just including them in the devshell so I can test local pacakge
  # derivations.
  packages = [
    coreutils
    jq
    curl
    htmlq
    yt-dlp
    #    yt-dlp-wrapped
    ytdl-sub
    qemu-uefi-wrapper
    hwatch
    altshfmt
    no-more-secrets
    hponcfg
    nix-update
    open-webui-cli
    treefmt
    statix
    nixfmt-rfc-style
  ];
}
