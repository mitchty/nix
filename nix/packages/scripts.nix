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
    for s in cr cb pikvm cacheclean b crane; do
      install -m755 $src/$s.sh $out/bin/$s
    done
    for l in notify nixgc; do
      install -m755 $src/$l $out/bin/$l
    done
    patchShebangs $out/bin
  '';

  meta = {
    description = "My bundle of script nonsense";
    maintainers = with lib.maintainers; [ mitchty ];
  };
}
