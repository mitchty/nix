{ ... }: {
  # Default normal imports for everything...
  imports = [
    ./sysrq.nix
    ./nix.nix
    ./network.nix
    ./console.nix
    ./users.nix
    ./ssh.nix
    ./pkgs.nix
    ./shell.nix
    ./hosts.nix
    ./mdns.nix
  ];
}
