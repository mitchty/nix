{
  inputs,
  ...
}:
{
  imports = with inputs.self.crossplatformModules; [
    nix
    debug
  ];
}
