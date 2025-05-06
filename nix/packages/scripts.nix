{
  stdenv,
  lib,
  pkgs,
}:
stdenv.mkDerivation rec {
  pname = "scripts";
  version = "0.1.0";

  src = ../../src;

  buildInputs = [ pkgs.makeWrapper ];

  # Note not installing everything in here, just onesie twosie script picking
  # what matters.
  installPhase = ''
    install -dm755 $out/bin
    install -m755 $src/cr.sh $out/bin/cr
    install -m755 $src/cb.sh $out/bin/cb
    install -m755 $src/notify $out/bin/notify
    install -m755 $src/nixgc $out/bin/nixgc
    patchShebangs $out/bin
  '';

  meta = {
    description = "My bundle of script nonsense";
    maintainers = with lib.maintainers; [ mitchty ];
  };
}
