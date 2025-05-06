{
  inputs,
  pkgs,
  ...
}:
{
  home = {
    packages =
      with pkgs;
      [
        scripts # TODO: should pull this package apart and make scripts-macos scripts-blah future mitch problem
        hatools
        altshfmt
        no-more-secrets
        open-webui-cli
        (pkgs.hiPrio clang)
        asm-lsp
        clang-tools
        gcc11
        entr
        gnumake
        shellcheck
        shellspec
        shfmt
        nodePackages.bash-language-server
        yaml-language-server
        ripgrep
      ]
      ++ (with inputs.fenix.packages.${pkgs.system}.stable; [
        rustc
        rust-src
        rustfmt
        rust-analyzer
      ])
      ++ [ (pkgs.hiPrio inputs.fenix.packages.${pkgs.system}.stable.clippy) ];
  };
}
