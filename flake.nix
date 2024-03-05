{
  description = "mitchty nixos flake setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    # Not overriding inputs.nixpkgs due to
    # https://github.com/nix-community/disko/blob/master/flake.nix#L4
    disko.url = "github:nix-community/disko";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , nixos-generators
    , deploy-rs
    , agenix
    , disko
    , ...
    }:
    let
      inherit (nixpkgs.lib) attrValues makeOverridable nixosSystem mkForce mkDefault;

      system = "x86_64_linux";
      pkgs = import nixpkgs {
        inherit system;
      };

      # For the future...
      supportedSystems = [
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Setup an auto installing iso image using disko
      mkAutoDiskoIso = pkgs: nixos-generators.nixosGenerate {
        inherit pkgs;
        format = "install-iso";
        # We always include nixos disko modules for install isos
        modules = [
          disko.nixosModules.default
        ];
      };

      mylib = import ./lib/default.nix;

      inherit (mylib) mkAutoInstaller;
    in
    {
      packages = forAllSystems
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          rec {
            vmZfsMirrorSystem = (makeOverridable nixosSystem) rec {
              inherit system;
              modules = [ ];
              specialArgs = {
                inherit inputs;
              };
            };
            vmZfsMirror = mkAutoDiskoIso pkgs;
            # 2 disk auto mirror setup in disko setup for qemu vm
            # testing/validation (re)uses nixosConfiguration ^^^ for disko
            # install. Note all disko setup is opinionated in that its setup to
            # only use labels or partlabels that lets us create what would be in
            # hardware-configuration.nix ourselves which seems to only include
            # uuid device by default and I want to make that mostly transparent.
            #
            # For now only validating efi bootable stuff out of laziness and
            # need as I can use systemctl reboot --firmware-setup to make it
            # easy to pick disparate devices to test booting off of to manually
            # validate (for now) until at least I can better figure out how to
            # set efi vars to change devices once I figure that out.
            isoZfsTest = mkAutoInstaller vmZfsMirrorSystem;
            default = isoZfsTest;
          });
      checks = forAllSystems
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            # Ensure all our formatting is kosher in nix lande for now.
            formatting =
              pkgs.writeShellApplication
                {
                  name = "formatting";
                  runtimeInputs = with pkgs; [
                    nixpkgs-fmt
                    deadnix
                  ];
                  # TODO: enable deadnix, for now it just wants to remove stuff
                  # I am working on that I might enable again later
                  text = ''
                    nixpkgs-fmt --check "$@"
                    #            deadnix --edit "$@"
                  '';
                };
            shell = pkgs.writeShellApplication
              {
                name = "shellchecks";
                runtimeInputs = with pkgs; [
                  shellcheck
                  shellspec
                  ksh
                  oksh
                  zsh
                  bash
                  findutils
                  # abusing python3 for pty support cause shellspec needs it for
                  # some output or another to run in nix given nix runs top most
                  # pid without a pty. We could do this any way we can get a pty
                  # so that shellspec can run but this is fine.
                  python3
                ];
                text = ''
                  shellcheck --severity warning --shell sh "$(find ${./.} -type f -name '*.sh')" --external-sources
                  for shell in ${pkgs.ksh}/bin/ksh ${pkgs.oksh}/bin/ksh ${pkgs.zsh}/bin/zsh ${pkgs.bash}/bin/bash; do
                                        ${pkgs.python3}/bin/python3 -c 'import pty; pty.spawn("${pkgs.shellspec}/bin/shellspec -c ${./.} --shell '$shell' -x")'
                                      done
                '';
                # deploy-rs =
                #   builtins.mapAttrs
                #     (deployLib: deployLib.deployChecks self.deploy)
                #     deploy-rs.lib;
              };
          }
        );
    };
}
