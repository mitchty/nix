{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  config = {
    # In case anything tries to use /home and not /Users
    fileSystems."/home" = {
      device = "/Users";
      options = [ "bind" ];
    };
    # Simpler this way to sync junk with macos and use stuff like
    # git worktrees which uses full paths in .git files.
    users.users.mitch.home = "/Users/mitch";
  };
}
