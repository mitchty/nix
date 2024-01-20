{ lib, ... }:
# Helper util functions for the rest of the flake. LOTS TO DO HERE!

let
  inherit (nixpkgs.lib) attrValues makeOverridable nixosSystem;


  notDefaultNix = (f: ! lib.hasSuffix "default.nix" f);
  isNix = (f: lib.hasSuffix ".nix" f);
  # Recursively list all nix files.
  nixFiles = path: lib.filter (f: isNix f && notDefaultNix f) (lib.filesystem.listFilesRecursive path);
  # Use ^^ to import everything in a dir recursively, minus the default.nix
  # which import will use implicitly.
  importPath = path: builtins.map import nixFiles path;

  homeDir = system: user: with nixpkgs.legacyPackages.${system}.stdenv;
    if isDarwin then
      "/Users/${user}"
    else if isLinux then
      "/home/${user}"
    else "";

  nixOSModules = attrValues
    {
      users = import ./modules/users.nix;
    } ++ [
    home-manager.nixosModules.home-manager
    nur.nixosModules.nur
    ./modules/nixos
    agenix.nixosModules.age
    "${inputs.nixpkgs-pacemaker}/nixos/modules/${pacemakerPath}"
    (
      { config, ... }:
      let
        inherit (config.users) primaryUser;
      in
      {
        # From: https://github.com/NixOS/nixpkgs/blob/c653577537d9b16ffd04e3e2f3bc702cacc1a343/nixos/doc/manual/development/replace-modules.section.md
        #
        # TODO: Remove most of me once
        # https://github.com/NixOS/nixpkgs/pull/208298/files merged Disable the built.
        #
        # in pacemaker module in lieu of my fixed version until the basic version is
        # merged.
        #
        # Will also be testing out some other module updates to make it less of a PITA to use.
        disabledModules = [ pacemakerPath ];

        nixpkgs = nixpkgsConfig [ ];
        users.users.${primaryUser}.home = homeDir "x86_64-linux" primaryUser;
        home-manager.useGlobalPkgs = true;
        home-manager.users.${primaryUser} = homeManagerCommonConfig;
        home-manager.extraSpecialArgs =
          {
            inherit inputs nixpkgs;
            age = config.age;
            role = config.services.role;
          };
        nix.registry.my.flake = self;
      }
    )
  ];

  mkNixOSSystem =
    { hostname
    , system
    , roles
    , users
    , overlays
    }: nixosSystem {
      inherit system;
      modules = nixOSModules ++ [
        ./hosts/nexus/configuration.nix
      ] ++ [{
        users.primaryUser = "mitch";
      }];
    };

in
{ }
