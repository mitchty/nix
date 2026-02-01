{
  config,
  lib,
  ...
}:

with lib;

{
  options.mitchty.secrets = {
    hostKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "SSH host key for age encryption (ssh-ed25519 key)";
    };

    tags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Tags for automatic secrets.nix generation (e.g., wireguard, cifs, wifi, backup)";
      example = [
        "wireguard"
        "cifs"
        "wifi"
      ];
    };

    isAdmin = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this host/user can decrypt admin secrets";
    };
  };

  # No config needed, this is just metadata
  config = { };
}
