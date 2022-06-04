{ ... }: {
  # Default normal imports for everything...
  imports = [
    ./nix.nix
    ./network.nix
    ./console.nix
    ./users.nix
    ./ssh.nix
    ./pkgs.nix
    ./shell.nix
    ./mdns.nix
  ];
}
