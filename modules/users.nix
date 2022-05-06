{ lib, ... }:

let
  inherit (lib) mkOption types;
in

{
  options = {
    users.primaryUser = mkOption {
      description = ''
        The primary user for a system. Since I mostly deal with just "simple" single user setups this is "fine".
      '';
      type = with types; nullOr string;
      default = null;
    };
    users.primaryGroup = mkOption {
      description = ''
        The primary group, if applicable for ^^ for a system.
      '';

      type = with types; nullOr string;
      default = null;
    };
  };
}
