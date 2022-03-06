{ ... }: {
  # Until I get the nix firewall setup
  networking.extraHosts = ''
    10.10.10.190 dfs1.home.arpa dfs1
    10.10.10.200 nexus.home.arpa nexus
    10.10.10.249 mb.home.arpa mb
  '';
}
