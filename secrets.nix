let
  # User keys
  mitch = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILGJSGtoArRe0CMGOek5iZXOdLikEvrulvjVUXpx4jLV";

  ageadmins = [ mitch ];

  # Host keys
  mb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINhaAD9U8kHtlMrFsy8vytWITHLe55DYy8kObDhoMqTO";
  mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaNLdykXNG7SbXyEFV3q1OVevNbIxSb8Of0AnSLxR11";
  wm2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNzRSDjB8WJHSEepNu2GTrZIgFWprv+wMnX6xbeoD0U";
  rtx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKBaFOFERMbg/d7DHrTBJ7pPKiJhwxFadQZlagalg51/";

  plx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK2IZnIu0StYczf9Z4iJNDpEZt+Wjo8LjqDrlmd2yX4l";
  ark = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDFFvNk88g2x8R5cK1K+iVGQT1Lu1IFKZwSp75s2xegB";
  gw0 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyjyOCeUEtKb7hLISbPzwkrrSDKQU5JGJ1R1Sw7MZga";

  # Test vm keys
  vm-simple = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuH9BdXTgFflW0uDF1ytFdgHxIBx0NDrHB4jqCjKhQB";
  vm-mirror = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKVbKj5m/pk2VKzIjX7/zM7MB5BG03kxTv22PowvtexS";
  vm-raid = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvmcCgF67R0DdVAZ+7iuww0dIejSYBNrmJH75AeKdwZ";

  allnixos = [
    rtx
    wm2

    plx
    ark
    gw0

    vm-simple
    vm-mirror
    vm-raid
  ];

  allmacos = [
    mb
    mbp
  ];

  # To make the following a skosh simpler/easier
  homeusers = [ mitch ];
  homehosts = allmacos ++ allnixos;

  git = homehosts ++ homeusers;

  # TODO: Get backups automagically working at some point with kopia
  backup = allmacos ++ [
    rtx
    ark
    wm2
  ];

  # Some secrets should be usable everywhere
  allusers = homeusers;
  allhosts = homehosts;

  # Mostly for the canary secret for testing
  everything = allusers ++ allhosts;

  # Cifs hosts
  cifs = [
    wm2
    rtx

    plx
    ark

    vm-simple
    vm-mirror
    vm-raid
  ];

  # wifi connections
  wifi = [ wm2 ];

  # Public wireguard keys, still sticking em here cause I only need to share
  # amongst my nodes not the world.
  wireguard = [
    mbp
    gw0
  ];
in
{
  # Just a canary file to know if things are working or not, otherwise unused
  # TODO: yeet this into a git hook or something?
  "secrets/canary.age".publicKeys = everything;

  # For updating cloudflare dns
  "secrets/dns/home.mitchty.net.age".publicKeys = [ gw0 ] ++ ageadmins;

  # Wireguard public keys, shared amongst all wireguard nodes.
  "secrets/wireguard/pub/mbp.age".publicKeys = [ wireguard ] ++ ageadmins;
  "secrets/wireguard/pub/rtx.age".publicKeys = [ wireguard ] ++ ageadmins;
  "secrets/wireguard/pub/gw0.age".publicKeys = [ wireguard ] ++ ageadmins;

  # Private is per host obvs
  "secrets/wireguard/prv/mbp.age".publicKeys = [ mbp ] ++ ageadmins;
  "secrets/wireguard/prv/rtx.age".publicKeys = [ rtx ] ++ ageadmins;
  "secrets/wireguard/prv/gw0.age".publicKeys = [ gw0 ] ++ ageadmins;

  # For authenticated git push/pull mainly.
  "secrets/git/netrc.age".publicKeys = git ++ ageadmins;
  "secrets/git/gh-cli-pub.age".publicKeys = git ++ ageadmins;

  # nixos specific
  "secrets/passwd/root.age".publicKeys = allnixos ++ ageadmins;
  "secrets/passwd/mitch.age".publicKeys = allnixos ++ ageadmins;

  # cifs mount user/pass files
  "secrets/cifs/plex.age".publicKeys = cifs ++ ageadmins;
  "secrets/cifs/mitch.age".publicKeys = cifs ++ ageadmins;

  # Wifi networkmanager setup
  "secrets/wifi/lostfox.age".publicKeys = wifi ++ ageadmins;
  "secrets/wifi/newerhotness.age".publicKeys = wifi ++ ageadmins;
  "secrets/wifi/gambit.age".publicKeys = wifi ++ ageadmins;
  "secrets/wifi/pp.age".publicKeys = wifi ++ ageadmins;
}
