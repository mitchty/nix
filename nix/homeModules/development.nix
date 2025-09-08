{
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      (pkgs.hiPrio clang)
      clang-tools
      entr
      hatools
      hyperfine
      idris2
      no-more-secrets
      open-webui-cli
      ripgrep
    ];
  };
}
