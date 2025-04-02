{ outputs
, lib
, ...
}:
# TODO: this kinda works but not sure its a good idea or not, future mitch problem suck it
let
  moduleEnabled = this: module: builtins.all (m: builtins.elem m this) (lib.splitString "+" module);
in
{
  applyNixosModules = moduleList:
    let
      theseModules = lib.filterAttrs (n: _v: moduleEnabled moduleList n) outputs.nixosModules;
    in
    {
      imports = builtins.attrValues theseModules;
    };
  test = 5;
}
