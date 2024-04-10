{ lib, inputs, ... }: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  #  perSystem = { pkgs, ... }: {
  perSystem = { pkgs, ... }: {
    # _module.args.pkgs = inputs'.nixpkgs.legacyPackages.extend inputs.self.overlays.defaults;
    # _module.args.pkgs = import inputs.nixpkgs {
    #   inherit system;
    #   overlays = [
    #     self'.overlays.defaults
    #     self'.overlays.development
    #     self'.overlays.emacs
    #     self'.overlays.personal
    #   ];
    # };

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

          # shellspec = {
          #   command = "python";
          #       shell = pkgs.writeShellApplication
          #         {
          #           name = "shellchecks";
          #           runtimeInputs = with pkgs; [
          #             shellcheck
          #             shellspec
          #             ksh
          #             oksh
          #             zsh
          #             bash
          #             findutils
          #             # abusing python3 for pty support cause shellspec needs it for
          #             # some output or another to run in nix given nix runs top most
          #             # pid without a pty. We could do this any way we can get a pty
          #             # so that shellspec can run but this is fine.
          #             python3
          #           ];
          #           text = ''
          #             shellcheck --severity warning --shell sh "$(find ${./.} -type f -name '*.sh')" --external-sources
          #             for shell in ${pkgs.ksh}/bin/ksh ${pkgs.oksh}/bin/ksh ${pkgs.zsh}/bin/zsh ${pkgs.bash}/bin/bash; do
          #                                   ${pkgs.python3}/bin/python3 -c 'import pty; pty.spawn("${pkgs.shellspec}/bin/shellspec -c ${./.} --shell '$shell' -x")'
          #                                 done
          # };

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
