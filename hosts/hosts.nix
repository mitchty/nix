{ ... }: {
  # Until I get the nix firewall setup
  networking.extraHosts = ''
    10.10.10.190 dfs1.home.arpa dfs1
    10.10.10.200 slaptop.home.arpa slaptop
    10.10.10.249 mb.home.arpa mb
  '';
}
