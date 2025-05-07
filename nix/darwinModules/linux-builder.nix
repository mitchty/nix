{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # https://nixcademy.com/posts/macos-linux-builder/
  # https://github.com/nix-darwin/nix-darwin/blob/master/modules/nix/linux-builder.nix
  nix.linux-builder = {
    enable = true;
    ephemeral = true;
    maxJobs = 4;
    config = {
      virtualisation = {
        darwin-builder = {
          diskSize = 40 * 1024;
          memorySize = 8 * 1024;
        };
        cores = 6;
      };
    };
    settings.trusted-users = [ "@admin" ];
  };
}
