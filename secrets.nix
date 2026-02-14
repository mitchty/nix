let
  # Get the secrets metadata from the flake
  flake = builtins.getFlake (toString ./.);
  inherit (flake) secrets;

  # Helper to get keys for specific hostnames
  # Helper to get keys by tag? Needed anymore? My prior thing kinda used it but
  # not sure it matters with this automagic setup
  inherit (secrets) mkKeys getTag; # TODO: getTag needed anymore?
in
{
  # Just a canary file to know if things are working or not, otherwise unused
  "secrets/canary.age".publicKeys = secrets.allHostKeys ++ [
    secrets.adminKey
    secrets.hmKey
  ];

  # For updating cloudflare dns
  "secrets/dns/home.mitchty.net.age".publicKeys = mkKeys { hosts = [ "gw0" ]; };

  # Wireguard public keys, shared amongst all wireguard tagged nodes cause duh
  "secrets/wireguard/pub/mbp.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };
  "secrets/wireguard/pub/rtx.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };
  "secrets/wireguard/pub/gw0.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };
  "secrets/wireguard/pub/wm2.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };
  "secrets/wireguard/pub/plx.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };
  "secrets/wireguard/pub/ark.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };
  "secrets/wireguard/pub/ip.age".publicKeys = mkKeys { tags = [ "wireguard" ]; };

  # Private is per host
  "secrets/wireguard/prv/mbp.age".publicKeys = mkKeys { hosts = [ "mbp" ]; };
  "secrets/wireguard/prv/rtx.age".publicKeys = mkKeys { hosts = [ "rtx" ]; };
  "secrets/wireguard/prv/gw0.age".publicKeys = mkKeys { hosts = [ "gw0" ]; };
  "secrets/wireguard/prv/wm2.age".publicKeys = mkKeys { hosts = [ "wm2" ]; };
  "secrets/wireguard/prv/plx.age".publicKeys = mkKeys { hosts = [ "plx" ]; };
  "secrets/wireguard/prv/ark.age".publicKeys = mkKeys { hosts = [ "ark" ]; };
  "secrets/wireguard/prv/ip.age".publicKeys = secrets.allHostKeys ++ [
    secrets.adminKey
    secrets.hmKey
  ];

  # For authenticated git push/pull mainly - all hosts get these for now... I
  # should make a git tag.
  "secrets/git/netrc.age".publicKeys = secrets.allHostKeys ++ [
    secrets.adminKey
    secrets.hmKey
  ];
  "secrets/git/gh-cli-pub.age".publicKeys = secrets.allHostKeys ++ [
    secrets.adminKey
    secrets.hmKey
  ];

  # SSH key used for home-manager agenix, kinda a 2 phase approach where
  # nixos/darwin decrypt this into $HOME/.ssh/blah and then home-manager agenix
  # uses that to decrypt home-manager files.
  "secrets/ssh/id_ed25519-home-manager.age".publicKeys = secrets.allHostKeys ++ [
    secrets.adminKey
  ];
  "secrets/ssh/id_ed25519-home-manager.pub.age".publicKeys = secrets.allHostKeys ++ [
    secrets.adminKey
  ];

  # Atuin encryption key - shared across ALL hosts (single key for synced history)
  "secrets/atuin/key.age".publicKeys = secrets.allHostKeys ++ [
    secrets.adminKey
    secrets.hmKey
  ];

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
#crypt/ssh/id_ed25519-home-manager_key
#crypt/ssh/id_ed25519-home-manager_key.pub
#secrets/ssh/id_ed25519-home-manager_key
#secrets/ssh/id_ed25519-home-manager_key.pub
#cat "${dest}/privatekey" | EDITOR='cp /dev/stdin' agenix -e "${wgdest}/prv/${host}.age"
#cat "${dest}/publickey" | EDITOR='cp /dev/stdin' agenix -e "${wgdest}/pub/${host}.age"
#   cat crypt/ssh/id_ed25519-home-manager.pub | EDITOR='cp /dev/stdin' agenix -e secrets/ssh/id_ed25519-home-manager.pub.age"
# cat crypt/ssh/id_ed25519-home-manager | EDITOR='cp /dev/stdin' agenix -e secrets/ssh/id_ed25519-home-manager.age"

# cat crypt/atuin/key | EDITOR='cp /dev/stdin' agenix -e secrets/atuin/key.age"
