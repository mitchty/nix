_: {
  # To allow for git workspaces which embed the full path
  systemd.tmpfiles.rules = [
    "L+ /Users - - - - /home"
  ];
}
