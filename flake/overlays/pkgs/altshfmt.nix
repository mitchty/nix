{ pkgs
, makeWrapper
, mkDerivation
, fetchFromGitHub
}:
mkDerivation rec {
  pname = "altshfmt";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "shellspec";
    repo = "altshfmt";
    rev = "v${version}";
    sha256 = "sha256-iBb5aqUa7LpR3cpIFUciW+HkTZvUPhw/R+4EcRFxQpo=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -dm755 $out $out/bin
    wrapProgram "$out/bin/altshfmt" \
      --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.gawk pkgs.shfmt ]}"
  '';

  meta = {
    mainProgram = "altshfmt";
    description = "Alternative shfmt wrapper";
    maintainers = with pkgs.lib.maintainers; [ mitchty ];
    homepage = "https://github.com/shellspec/altshfmt";
  };
}
