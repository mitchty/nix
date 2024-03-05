{ lib, inputs, ... }: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = { pkgs, ... }: {
    treefmt = {
      # Used to find the project root
      projectRootFile = "flake.lock";

      programs = {
        #            rustfmt.enable = true;
        nixpkgs-fmt.enable = true;
        deadnix.enable = true;
        shellcheck.enable = true;
        shfmt.enable = true;
        statix.enable = true;
      };

      settings.formatter =
        let
          sh-includes = [ "*.sh" "direnvrc" ];
          spec-excludes = [ "spec/*_spec.sh" ];
          crypt-excludes = [ "restic-env.sh" ];
        in
        {
          # TODO: Remove when this: https://github.com/numtide/treefmt/issues/241
          # is fixed via: https://github.com/nerdypepper/statix/issues/69
          statix = {
            command = lib.mkForce "sh";
            options = [
              "-euc"
              "for file in \"$@\"; do ${lib.getExe pkgs.statix} fix \"$file\"; done"
            ];
          };
          shellcheck = {
            options = [
              "--external-sources"
              "--severity"
              "warning"
              "--shell"
              "sh"
            ];
            includes = sh-includes;
            excludes = crypt-excludes;
          };

          shfmt = {
            options = [
              "-ci"
              "-i"
              "2"
              "-bn"
              "-sr"
            ];
            includes = sh-includes;
            excludes = spec-excludes ++ crypt-excludes;
          };
        };
    };
  };
}
