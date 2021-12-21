{ ... }: {
  # Lets let arm stuff run easily
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
