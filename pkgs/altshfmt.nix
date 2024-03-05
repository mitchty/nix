{ stdenv
, lib
, pkgs
, makeWrapper
}:
with lib; stdenv.mkDerivation rec {
  pname = "altshfmt";
  version = "0.2.0";

  src = pkgs.fetchFromGitHub {
    owner = "shellspec";
    repo = "altshfmt";
    rev = "v${version}";
    sha256 = "sha256-iBb5aqUa7LpR3cpIFUciW+HkTZvUPhw/R+4EcRFxQpo=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -dm755 $out
    install -dm755 $out/bin
    install -m755 altshfmt $out/bin
    wrapProgram "$out/bin/altshfmt" \
      --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.gawk pkgs.shfmt ]}"
  '';

  meta = {
    mainProgram = "altshfmt";
    description = "Alternative shfmt wrapper";
    maintainers = with lib.maintainers; [ mitchty ];
    homepage = "https://github.com/shellspec/altshfmt";
  };
}
