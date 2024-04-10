_self: super: {
  hatools =
    let
      inherit (super.stdenv) mkDerivation;
      inherit (super.pkgs) fetchFromGitHub;
      inherit (super) pkgs;
    in
    # Ye olde halockrun and hatimerun
    mkDerivation rec {
      oname = "fatalmind";
      pname = "hatools";
      version = "2.1.4";

      src = fetchFromGitHub {
        sha256 = "sha256-Pl5hbL7aHK261/ReQ7kmHyoEprjD/sOL9kFSXR2g4Ok=";
        rev = "v2_14";
        owner = oname;
        repo = pname;
      };

      nativeBuildInputs = [
        pkgs.autoreconfHook
        pkgs.gnumake
        pkgs.gcc
      ];

      installPhase = ''
        make install DESTDIR=""
      '';
    };
}
