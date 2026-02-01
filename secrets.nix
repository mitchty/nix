let
  # Get the secrets metadata from the flake
  flake = builtins.getFlake (toString ./.);
  secrets = flake.mitchtysecrets;

  # Helper to get keys for specific hostnames
  # Helper to get keys by tag? Needed anymore? My prior thing kinda used it but
  # not sure it matters with this automagic setup
  inherit (secrets) mkKeys getTag; # TODO: getTag needed anymore?
in
{
  # Just a canary file to know if things are working or not, otherwise unused
  "secrets/canary.age".publicKeys = secrets.allHostKeys ++ [ secrets.adminKey ];

  # For updating cloudflare dns
  "secrets/dns/home.mitchty.net.age".publicKeys = mkKeys { hosts = [ "gw0" ]; };

  # Wireguard public keys, shared amongst all wireguard tagged nodes cause duh
  "secrets/wireguard/pub/mbp.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };
  "secrets/wireguard/pub/rtx.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };
  "secrets/wireguard/pub/gw0.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };
  "secrets/wireguard/pub/wm2.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };
  "secrets/wireguard/pub/plx.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };
  "secrets/wireguard/pub/ark.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };

  # Private is per host
  "secrets/wireguard/prv/mbp.age".publicKeys = mkKeys { hosts = [ "mbp" ]; };
  "secrets/wireguard/prv/rtx.age".publicKeys = mkKeys { hosts = [ "rtx" ]; };
  "secrets/wireguard/prv/gw0.age".publicKeys = mkKeys { hosts = [ "gw0" ]; };
  "secrets/wireguard/prv/wm2.age".publicKeys = mkKeys { hosts = [ "wm2" ]; };
  "secrets/wireguard/prv/plx.age".publicKeys = mkKeys { hosts = [ "plx" ]; };
  "secrets/wireguard/prv/ark.age".publicKeys = mkKeys { hosts = [ "ark" ]; };

  # For authenticated git push/pull mainly - all hosts get these for now... I
  # should make a git tag.
  "secrets/git/netrc.age".publicKeys = secrets.allHostKeys ++ [ secrets.adminKey ];
  "secrets/git/gh-cli-pub.age".publicKeys = secrets.allHostKeys ++ [ secrets.adminKey ];

  # All nixos tagged node secrets
  "secrets/passwd/root.age".publicKeys = mkKeys { tags = [ "nixos" ]; };
  "secrets/passwd/mitch.age".publicKeys = mkKeys { tags = [ "nixos" ]; };

  # And for cifs/backup related junk cifs mount user/pass files
  "secrets/cifs/plex.age".publicKeys = mkKeys { tags = [ "cifs" ]; };
  "secrets/cifs/mitch.age".publicKeys = mkKeys { tags = [ "cifs" ]; };
  "secrets/cifs/backup.age".publicKeys = mkKeys { tags = [ "backup" ]; };

  # This is really just wm2 atm but Wifi networkmanager file data
  "secrets/wifi/lostfox.age".publicKeys = mkKeys { tags = [ "wifi" ]; };
  "secrets/wifi/newerhotness.age".publicKeys = mkKeys { tags = [ "wifi" ]; };
  "secrets/wifi/gambit.age".publicKeys = mkKeys { tags = [ "wifi" ]; };
  "secrets/wifi/pp.age".publicKeys = mkKeys { tags = [ "wifi" ]; };
}
