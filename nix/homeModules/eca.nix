{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  #  ~/.config/eca/commands/check-performance.md
  home.file.".config/eca/commands/memory.md".source = ../../static/memory.md;
  #      ~/.config/eca/commands/check-performance.md

}
