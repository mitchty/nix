{
  lib,
  pkgs,
}:
pkgs.stdenvNoCC.mkDerivation rec {
  pname = "scripts";
  version = "0.1.0";

  src = ../../src;

  buildInputs = [ pkgs.makeWrapper ];

  # Deps for the scripts basically
  nativeBuildInputs = with pkgs; [
    cargo-cache
    (fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
  ];

  # Note not installing everything in here, just onesie twosie script picking
  # what matters.
  installPhase = ''
    install -dm755 $out/bin
    for s in b cacheclean cb cdu cr crane git-exec mutmon pikvm; do
      install -m755 $src/$s.sh $out/bin/$s
    done
    for l in nixgc notify; do
      install -m755 $src/$l $out/bin/$l
    done
    patchShebangs $out/bin
  '';

  meta = {
    description = "My bundle of script nonsense";
    maintainers = with lib.maintainers; [ mitchty ];
  };
}
