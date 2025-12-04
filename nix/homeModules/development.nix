{
  pkgs,
  lib,
  ...
}:
{
  home = {
    packages = with pkgs; [
      (lib.hiPrio clang)
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
