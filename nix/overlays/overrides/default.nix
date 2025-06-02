self: super: {
  asm-lsp = super.asm-lsp.overrideAttrs (old: {
    meta.platforms = self.lib.platforms.unix;
    buildInputs =
      old.buildInputs
      ++ self.lib.optionals self.stdenv.isDarwin [
        self.darwin.apple_sdk.frameworks.SystemConfiguration
      ];
  });

  transcrypt = super.transcrypt.overrideAttrs (old: rec {
    patches = old.patches or [ ] ++ [
      (super.fetchpatch {
        name = "suppress-openssl-pbkdf2-warnings";
        url = "https://github.com/elasticdog/transcrypt/compare/suppress-openssl-pbkdf2-warnings.diff";
        sha256 = "sha256-wRMx/Kbkm/Xpl1aaX9jjk6xMXZf6seEg5BhkZ34WEpI=";
      })
    ];
  });

  # Latest version of powertop was like 3-4 years ago, this patch is from 2 years ago
  #
  # Be nice if they plopped out a new release at some point.
  powertop = super.powertop.overrideAttrs (old: rec {
    patches = old.patches or [ ] ++ [
      (super.fetchpatch {
        name = "add-auto-tune-dump";
        url = "https://github.com/fenrus75/powertop/commit/fa916f11b7cd5dadeb838068e2a0aaec03e062ff.diff";
        sha256 = "sha256-4/FGmf5xxvyzLLvl4BBkntQL7abR5vsMIgrMR7EoX7M=";
      })
    ];
  });

  pythonPackagesExtensions = super.pythonPackagesExtensions ++ [
    (pyfinal: pyprev: {
      # I keep getting errno 3 Temporary failure in name resolution on this for some reason now.
      #
      # Who does a POST to a webpage in a unit test though? Why is this data not
      # in the repo ungh ai tooling is as bad as the llm responses they give.
      langchain-community = pyprev.langchain-community.overridePythonAttrs (old: {
        doCheck = false;
        doInstallCheck = false;
        dontCheck = true;
        disabledTests = [
          "test_llm_caching"
          "test_llm_caching_async"
        ] ++ old.disabledTests;
      });
      open-webui = pyprev.open-webui.overridePythonAttrs (old: {
        dependencies =
          old.dependencies
          ++ (with super.pkgs.python3Packages; [
            emoji
            iso-639
            langdetect
          ]);
      });
    })
  ];
}
