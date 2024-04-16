{ inputs
, ...
}:
{
  imports = [
    # ../illumi/programs/env.nix
    # ../illumi/programs/pkgs.nix
    # ../illumi/system/fonts.nix
    # inputs.nix-index-database.nixosModules.nix-index
    {
      programs.command-not-found.enable = false;
    }
  ];
}
