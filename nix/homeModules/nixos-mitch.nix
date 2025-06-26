{
  inputs,
  pkgs,
  ...
}:
{
  home = {
    sessionVariables = {
      CARGO_TARGET_DIR = "~/.cache/cargo-bitbucket";
    };
    packages = with pkgs; [
      httpie
    ];
  };
}
