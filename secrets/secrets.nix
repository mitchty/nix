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
  dfs1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMIIXtwtlXD59ni6Y/+jYr2opNqvG6sTTXKbVN4OBLTA";

  cl1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOxV4KEVMkikEM4L9QCvd8QcMwvDK3nryBL28L0BFffZ";
  cl2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9/+zDNc2RTZNn25SN0z/iKBc6RrT+uleTUaJT+nPIh";
  cl3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjWCCiZOEVe0MWZgpJSMQKrXdA26x8MuaTM7gI6qLYN";

  allnixos = [ dfs1 srv nexus wm2 gw cl1 cl2 cl3 ];

  # To make the following a skosh simpler/easier
  homeusers = [ mitch ];
  homehosts = [ mb ] ++ allnixos;

  git = homehosts ++ homeusers;
  restic = [ mb srv nexus ];

  # Some secrets should be usable everywhere
  allusers = homeusers;
  allhosts = homehosts;

  # Just router(s)
  router = [ gw ];

  # Mostly for the canary secret for testing
  everything = allusers ++ allhosts;
in
{
  # Just a canary file to know if things are working
  "canary.age".publicKeys = everything;

  # Using an env file that the launchd script sources, hopefully systemd can use
  # this directly as an env file
  "restic/env.sh.age".publicKeys = restic ++ ageadmins;

  # For authenticated git push/pull mainly.
  "git/netrc.age".publicKeys = git ++ ageadmins;
  "git/gh-cli-pub.age".publicKeys = git ++ ageadmins;

  # nixos specific
  "passwd/root.age".publicKeys = allnixos ++ ageadmins;
  "passwd/mitch.age".publicKeys = allnixos ++ ageadmins;

  # Only the router needs the the hostapd stuff
  "wifi/passphrase.age".publicKeys = router ++ ageadmins;
}
