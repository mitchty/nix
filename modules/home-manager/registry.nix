{ lib, inputs, ... }:
let
  inherit (lib) mapAttrs' nameValuePair mapAttrsToList;

  folder-inputs = mapAttrs' (n: v: nameValuePair ".nix-inputs/${n}" { source = v.outPath; }) inputs;

  registry = builtins.toJSON {
    flakes =
      mapAttrsToList
        (n: v: {
          exact = true;
          from = {
            id = n;
            type = "indirect";
          };
          to = {
            path = v.outPath;
            type = "path";
          };
        })
        inputs;
    version = 2;
  };
in
{
  home.file = folder-inputs // {
    ".config/nix/registry.json".text = registry;
  };
  home.activation.useFlakeChannels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    printf "modules/home-manager/registry.nix: Updating legacy ~/.nix* files/dirs for flakes\n" >&2
    $DRY_RUN_CMD rm -rf $VERBOSE_ARG ~/.nix-defexpr
    $DRY_RUN_CMD rm -rf $VERBOSE_ARG ~/.nix-channels
    $DRY_RUN_CMD ln -s $VERBOSE_ARG /dev/null $HOME/.nix-defexpr
    $DRY_RUN_CMD ln -s $VERBOSE_ARG /dev/null $HOME/.nix-channels
    $DRY_RUN_CMD ln -sf $VERBOSE_ARG /dev/null $HOME/.config/nixpkgs
  '';
}
