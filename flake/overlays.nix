{ inputs, ... }:
let
  personalBase = ../overlays/personal;
  emacsBase = ../overlays/emacs;
  #  developmentBase = ../overlays/development;
in
{
  flake.overlays = {
    # defaults = final: prev:
    #   prev.lib.composeManyExtensions
    #     (
    #       prev.lib.pipe defaultsBase [
    #         builtins.readDir
    #         builtins.attrNames

    #         #            (builtins.filter (n: n != "default.nix"))
    #         (map (f: import "${defaultsBase}/${f}"))
    #       ]
    #     )
    #     final
    #     prev;
    # defaults = import "${defaultsBase}/altshfmt.nix";
    defaults = _final: _prev: { };
    inputs = inputs.nixpkgs.lib.composeManyExtensions [
      inputs.rust.overlays.default
      inputs.emacs.overlays.default
    ];
    personal = final: prev:
      prev.lib.composeManyExtensions
        (
          prev.lib.pipe personalBase [
            builtins.readDir
            builtins.attrNames

            #            (builtins.filter (n: n != "default.nix"))
            (map (f: import "${personalBase}/${f}"))
          ]
        )
        final
        prev;
    emacs = final: prev:
      prev.lib.composeManyExtensions
        (
          prev.lib.pipe emacsBase [
            builtins.readDir
            builtins.attrNames

            #            (builtins.filter (n: n != "default.nix"))
            (map (f: import "${emacsBase}/${f}"))
          ]
        )
        final
        prev;
    # development = final: prev:
    #   prev.lib.composeManyExtensions
    #     (
    #       prev.lib.pipe developmentBase [
    #         builtins.readDir
    #         builtins.attrNames

    #         #            (builtins.filter (n: n != "default.nix"))
    #         (map (f: import "${developmentBase}/${f}"))
    #       ]
    #     )
    #     final
    #     prev;
  };
}
