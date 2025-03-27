{
  stdenv,
  lib,
  pkgs,
}:
stdenv.mkDerivation rec {
  oname = "bartobri";
  pname = "no-more-secrets";
  version = "1.0.1";

  src = pkgs.fetchFromGitHub {
    sha256 = "sha256-QVCEpplsZCSQ+Fq1LBtCuPBvnzgLsmLcSrxR+e4nA5I=";
    rev = "v${version}";
    owner = oname;
    repo = pname;
  };

  nativeBuildInputs = [
    pkgs.gnumake
    pkgs.gcc
    pkgs.git
  ];

  buildPhase = ''
    make all
  '';

  installPhase = ''
    make install prefix=$out
  '';

  meta = {
    mainProgram = "nms";
    description = "no-more-secrets haxor your text";
    maintainers = with lib.maintainers; [ mitchty ];
    homepage = "https://github.com/bartobri/no-more-secrets";
  };
}
