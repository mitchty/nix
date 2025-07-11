{ lib, ... }:
{
  #users.users.nixos.openssh.authorizedKeys.keys = builtins.readFile ../pub.key;
  users.extraUsers.nixos.openssh.authorizedKeys.keys = [
    (builtins.readFile ../pub.key)
  ];
}
