let
  # User keys
  mitch = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILGJSGtoArRe0CMGOek5iZXOdLikEvrulvjVUXpx4jLV";

  ageadmins = [ mitch ];

  # Host keys
  gw = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH0EYJsNFz7dWxdRSID5E5Qq/l+i17nNYoJKLAv4jG06";
  mb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINhaAD9U8kHtlMrFsy8vytWITHLe55DYy8kObDhoMqTO";
  srv = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsX6e+fhe/CxoGIbZ4auuk83H3sUK5XQhia8OWFz4pt";
  nexus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJCQJlqfzBYIjuWAIl72Q4o264vMEKWc4b+Tc30cqgtO";
  wm2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNzRSDjB8WJHSEepNu2GTrZIgFWprv+wMnX6xbeoD0U";
  rtx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKBaFOFERMbg/d7DHrTBJ7pPKiJhwxFadQZlagalg51/";

  cl1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOxV4KEVMkikEM4L9QCvd8QcMwvDK3nryBL28L0BFffZ";
  cl2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9/+zDNc2RTZNn25SN0z/iKBc6RrT+uleTUaJT+nPIh";
  cl3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjWCCiZOEVe0MWZgpJSMQKrXdA26x8MuaTM7gI6qLYN";

  allnixos = [ rtx srv wm2 gw cl1 cl2 cl3 nexus ];

  # To make the following a skosh simpler/easier
  homeusers = [ mitch ];
  homehosts = [ mb ] ++ allnixos;

  git = homehosts ++ homeusers;
  backup = [ mb srv wm2 ];

  # Some secrets should be usable everywhere
  allusers = homeusers;
  allhosts = homehosts;

  # Just router(s)
  #router = [ gw ];

  # Mostly for the canary secret for testing
  everything = allusers ++ allhosts;

  # Cifs hosts
  cifs = [ srv wm2 rtx nexus ];

  # ytdl
  ytdl = [ srv nexus ];

  # wifi connections
  wifi = [ wm2 ];
in
{
  # Just a canary file to know if things are working
  "canary.age".publicKeys = everything;

  # For authenticated git push/pull mainly.
  "git/netrc.age".publicKeys = git ++ ageadmins;
  "git/gh-cli-pub.age".publicKeys = git ++ ageadmins;

  # nixos specific
  "passwd/root.age".publicKeys = allnixos ++ ageadmins;
  "passwd/mitch.age".publicKeys = allnixos ++ ageadmins;

  # TODO moved to using an ap instead
  # Only the router needs the the hostapd stuff
  #  "wifi/passphrase.age".publicKeys = router ++ ageadmins;

  # cifs mount user/pass files
  "cifs/plex.age".publicKeys = cifs ++ ageadmins;
  "cifs/mitch.age".publicKeys = cifs ++ ageadmins;

  # Cookies for ytdl-sub
  "net/cookies.txt.age".publicKeys = ytdl ++ ageadmins;

  # Wifi networkmanager setup
  "wifi/lostfox.age".publicKeys = wifi ++ ageadmins;
  "wifi/newerhotness.age".publicKeys = wifi ++ ageadmins;
  "wifi/gambit.age".publicKeys = wifi ++ ageadmins;
}
