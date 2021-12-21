{ ... }: {
  users.users.root.initialPassword = "changeme";

  # And allow passwordless sudo for wheel
  security.sudo.extraConfig = ''
    %wheel ALL=(root) NOPASSWD:ALL
  '';
}
