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
        (pkgs.hiPrio clang)
        altshfmt
        asm-lsp
        clang-tools
        entr
        gcc11
        gnumake
        hatools
        hyperfine
        idris2
        no-more-secrets
        nodePackages.bash-language-server
        open-webui-cli
        ripgrep
        scripts # TODO: should pull this package apart and make scripts-macos scripts-blah future mitch problem
        shellcheck
        shellspec
        shfmt
        yaml-language-server
      ]
      ++ (with inputs.fenix.packages.${pkgs.system}.stable; [
        rust-analyzer
        rust-src
        rustc
        rustfmt
      ])
      ++ [ (pkgs.hiPrio inputs.fenix.packages.${pkgs.system}.stable.clippy) ];
  };
}
