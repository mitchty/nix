{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports =
    with inputs.self.homeModules;
    [
      macos-aerospace
    ]
    ++ [
      inputs.mac-app-util.homeManagerModules.default
    ];
}
