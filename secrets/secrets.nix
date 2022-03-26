let
  # User keys
  mitch = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILGJSGtoArRe0CMGOek5iZXOdLikEvrulvjVUXpx4jLV";

  # Host keys
  mb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINhaAD9U8kHtlMrFsy8vytWITHLe55DYy8kObDhoMqTO";
  nexus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJCQJlqfzBYIjuWAIl72Q4o264vMEKWc4b+Tc30cqgtO";
  dfs1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMIIXtwtlXD59ni6Y/+jYr2opNqvG6sTTXKbVN4OBLTA";
  workmb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINWlH6mfb4+v6z+uXNBDr+pPkhgTI7v3TMYl8UDNiKT1";

  # To make the following a skosh simpler/easier
  homeusers = [ mitch ];
  homehosts = [ mb nexus dfs1 ];

  workhosts = [ workmb ];

  git = [ mb nexus workmb ];
  restic = homeusers ++ homehosts;

  allnixos = [ dfs1 nexus ];

  # Some secrets should be usable everywhere
  allusers = homeusers;
  allhosts = homehosts ++ workhosts;

  everything = allusers ++ allhosts;
in
{
  # Just a canary file to know if things are working
  "canary.age".publicKeys = everything;

  # Using env vars for launchd atm, systemd probably will share same fate.
  "restic/env/RESTIC_PASSWORD.age".publicKeys = restic;
  "restic/env/AWS_ACCESS_KEY.age".publicKeys = restic;
  "restic/env/AWS_SECRET_KEY.age".publicKeys = restic;

  # For authenticated git push/pull mainly.
  "git/netrc.age".publicKeys = git;

  # nixos specific
  "passwd/root.age".publicKeys = allnixos;
  "passwd/mitch.age".publicKeys = allnixos;
}
