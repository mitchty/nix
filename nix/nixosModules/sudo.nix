# Let all wheel users use sudo
{
  # allow passwordless sudo for wheel
  config.security.sudo.extraConfig = ''
    %wheel ALL=(root) NOPASSWD:ALL
  '';
}
