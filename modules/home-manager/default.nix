{ ... }:

{
  # TODO: Migrate configuration/setup out of hosts/*.nix to a module setup
  imports = [
    ./nix-index.nix
  ];
}
