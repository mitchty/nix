pkgs: with pkgs; {
  # TODO: most of these really should be a check somehow
  #
  # For now I'm just including them in the devshell so I can test local pacakge
  # derivations.
  packages = [
    ytdl-sub
    hwatch
    altshfmt
    no-more-secrets
    hponcfg
    nix-update
    open-webui-cli
    treefmt
    nixfmt-rfc-style
  ];
}
