# ssh config
{
  # Let me ssh in by default
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
  };
}
