let
  # User keys
  mitch = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILGJSGtoArRe0CMGOek5iZXOdLikEvrulvjVUXpx4jLV";

  ageadmins = [ mitch ];

  # Host keys
  gw = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH0EYJsNFz7dWxdRSID5E5Qq/l+i17nNYoJKLAv4jG06";
  mb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINhaAD9U8kHtlMrFsy8vytWITHLe55DYy8kObDhoMqTO";
  mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaNLdykXNG7SbXyEFV3q1OVevNbIxSb8Of0AnSLxR11";
  srv = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsX6e+fhe/CxoGIbZ4auuk83H3sUK5XQhia8OWFz4pt";
  wm2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNzRSDjB8WJHSEepNu2GTrZIgFWprv+wMnX6xbeoD0U";
  rtx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKBaFOFERMbg/d7DHrTBJ7pPKiJhwxFadQZlagalg51/";

  cl1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOxV4KEVMkikEM4L9QCvd8QcMwvDK3nryBL28L0BFffZ";
  cl2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9/+zDNc2RTZNn25SN0z/iKBc6RrT+uleTUaJT+nPIh";
  cl3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjWCCiZOEVe0MWZgpJSMQKrXdA26x8MuaTM7gI6qLYN";

  allnixos = [
    rtx
    srv
    wm2
    gw
    cl1
    cl2
    cl3
  ];

  # To make the following a skosh simpler/easier
  homeusers = [ mitch ];
  homehosts = [
    mb
    mbp
  ] ++ allnixos;

  git = homehosts ++ homeusers;
  backup = [
    mb
    mbp
    srv
    wm2
  ];

  # Some secrets should be usable everywhere
  allusers = homeusers;
  allhosts = homehosts;

  # Just router(s)
  #router = [ gw ];

  # Mostly for the canary secret for testing
  everything = allusers ++ allhosts;

  # Cifs hosts
  cifs = [
    srv
    wm2
    rtx
  ];

  # ytdl
  ytdl = [ srv ];

  # wifi connections
  wifi = [ wm2 ];
in
{
  # Just a canary file to know if things are working or not, otherwise unused
  # TODO: yeet this into a git hook or something?
  "secrets/canary.age".publicKeys = everything;

  # For authenticated git push/pull mainly.
  "secrets/git/netrc.age".publicKeys = git ++ ageadmins;
  "secrets/git/gh-cli-pub.age".publicKeys = git ++ ageadmins;

  # nixos specific
  "secrets/passwd/root.age".publicKeys = allnixos ++ ageadmins;
  "secrets/passwd/mitch.age".publicKeys = allnixos ++ ageadmins;

  # cifs mount user/pass files
  "secrets/cifs/plex.age".publicKeys = cifs ++ ageadmins;
  "secrets/cifs/mitch.age".publicKeys = cifs ++ ageadmins;

  # TODO: Cookies for ytdl-sub, need to get all that junk into here somehow
  "secrets/net/cookies.txt.age".publicKeys = ytdl ++ ageadmins;

  # Wifi networkmanager setup
  "secrets/wifi/lostfox.age".publicKeys = wifi ++ ageadmins;
  "secrets/wifi/newerhotness.age".publicKeys = wifi ++ ageadmins;
  "secrets/wifi/gambit.age".publicKeys = wifi ++ ageadmins;
  "secrets/wifi/pp.age".publicKeys = wifi ++ ageadmins;
}
