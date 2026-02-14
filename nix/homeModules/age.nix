{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  # Use the home-manager specific SSH identity key for agenix decryption
  #
  # ~/.ssh/id_ed25519 or rsa aren't under any control for home-manager. Thats
  # all outside of nix and not on every node only nodes where I generally git
  # clone.
  age.identityPaths = [
    "${config.home.homeDirectory}/.ssh/id_ed25519-home-manager"
  ];

  # Trigger agenix secret decryption after home-manager activation
  home.activation.agenixReload = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    if pkgs.stdenv.isDarwin then
      ''
        # Restart the launchd agent to decrypt secrets
        $DRY_RUN_CMD launchctl kickstart -k gui/$UID/org.nix-community.home.activate-agenix || true
      ''
    else
      ''
        # Restart the systemd user service to decrypt secrets
        $DRY_RUN_CMD systemctl --user restart agenix.service || true
      ''
  );

  # Example canary secret - uncomment to test
  age.secrets."secrets/canary" = {
    file = ../../secrets/canary.age;
    path = config.home.homeDirectory + "/.age-canary";
  };
}
