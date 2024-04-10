# TODO: pr the overlay changes? Just needed a specific frameworkd for whatever
# to build not a huge deal. Its a rust app so not really linux specific.
self: super: rec {
  asm-lsp = super.asm-lsp.overrideAttrs (old: {
    meta.platforms = self.lib.platforms.unix;
    buildInputs = old.buildInputs ++ self.lib.optionals self.stdenv.isDarwin [
      self.darwin.apple_sdk.frameworks.SystemConfiguration
    ];
  });
}
