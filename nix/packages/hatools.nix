{
  stdenv,
  lib,
  pkgs,
}:
stdenv.mkDerivation rec {
  oname = "fatalmind";
  pname = "hatools";
  version = "2.1.4";

  src = pkgs.fetchFromGitHub {
    sha256 = "sha256-Pl5hbL7aHK261/ReQ7kmHyoEprjD/sOL9kFSXR2g4Ok=";
    rev = "v2_14";
    owner = oname;
    repo = pname;
  };

  nativeBuildInputs = [ pkgs.autoreconfHook ];

  installPhase = ''
    make install DESTDIR=""
  '';

  meta = {
    mainProgram = "halockrun";
    description = "halockrun and hatimerun utilities";
    maintainers = with lib.maintainers; [ mitchty ];
    homepage = "https://fatalmind.com/software/hatools/";
    platforms = lib.platforms.all;
  };
}
