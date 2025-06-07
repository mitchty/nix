{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    inputs.agenix.darwinModules.age
  ];

  # Migrated to homeModules, iff I need this in future for non user files in $HOME this is still here.
  #age.secrets
}
