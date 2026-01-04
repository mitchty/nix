final: prev: {
  # I want to use this with 2024 edition crates, this pr branch seems to work
  # with a generated cargo.lock file.
  cargo-unused-features = (
    prev.cargo-unused-features.overrideAttrs (
      old:
      let
        newSrc = prev.fetchFromGitHub {
          owner = "MTaliancich";
          repo = "cargo-unused-features";
          rev = "c882c83ca42bc0e744b0a1ac7fe164a5ea269906";
          hash = "sha256-BmzN+E9PBGS7oH67I9wDYNHF1aqJG9nYhjHJ4Z7pYkI=";
        };
      in
      {
        pname = "cargo-unused-features";
        version = "0.2.0-patched";
        src = newSrc;
        postPatch = ''
          cp ${./../patches/cargo-unused-features/Cargo.lock} Cargo.lock
        '';
        cargoDeps = prev.rustPlatform.importCargoLock {
          lockFile = ./../patches/cargo-unused-features/Cargo.lock;
        };
      }
    )
  );
}
