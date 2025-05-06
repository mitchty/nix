{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  system = {
    defaults = {
      dock = {
        autohide = true;
        autohide-delay = 0.1;
        orientation = "bottom";
      };
    };
  };
}
