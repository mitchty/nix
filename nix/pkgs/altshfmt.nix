{ pkgs
, ...
}:
let
  inherit (pkgs.lib) makeWrapper makeBinPath;
  inherit (pkgs.stdenv) mkDerivation;
  version = "0.2.0";
in
{
  mkDerivation = rec {
    name = "altshfmt";

    src = pkgs.fetchFromGitHub {
      owner = "shellspec";
      repo = name;
      rev = "v${version}";
      sha256 = "sha256-iBb5aqUa7LpR3cpIFUciW+HkTZvUPhw/R+4EcRFxQpo=";
    };

    nativeBuildInputs = [ makeWrapper ];

    installPhase = ''
      install -dm755 $out
      install -dm755 $out/bin
      install -m755 altshfmt $out/bin
      wrapProgram "$out/bin/altshfmt" --prefix PATH : "${makeBinPath [ pkgs.gawk pkgs.shfmt ]}"
    '';

    meta = {
      mainProgram = "altshfmt";
      description = "Alternative shfmt wrapper";
      maintainers = with pkgs.lib.maintainers; [ mitchty ];
      homepage = "https://github.com/shellspec/altshfmt";
    };
  };
}
