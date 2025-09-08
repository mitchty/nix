self: super: {
  asm-lsp = super.asm-lsp.overrideAttrs (old: {
    meta.platforms = self.lib.platforms.unix;
    buildInputs =
      old.buildInputs
      ++ self.lib.optionals self.stdenv.isDarwin [
        self.darwin.apple_sdk.frameworks.SystemConfiguration
      ];
  });

  transcrypt = super.transcrypt.overrideAttrs (old: {
    patches = old.patches or [ ] ++ [
      (super.fetchpatch {
        name = "suppress-openssl-pbkdf2-warnings";
        url = "https://github.com/elasticdog/transcrypt/compare/suppress-openssl-pbkdf2-warnings.diff";
        sha256 = "sha256-wRMx/Kbkm/Xpl1aaX9jjk6xMXZf6seEg5BhkZ34WEpI=";
      })
    ];
  });

  # Some wonky node.js bs seems to think it can mkdir anywhere apparently, no bueno cause the nix store's readonly
  # Aug 19 20:19:44 ark start-web[269884]:  ⨯ Failed to write image to cache FrdlaqhpdTaPM-DRuZSD5O-KySK7-9FHldWFIPzdR2w= Error: ENOENT: no such file or directory, mkdir '/nix/store/vmd7bl6qhvkndgp4bf37az9s26m0vw3g-karakeep-0.24.1/lib/karakeep/apps/web/.next/standalone/apps/web/.next/cache'
  # Aug 19 20:19:44 ark start-web[269884]:     at async Object.mkdir (node:internal/fs/promises:858:10)
  # Aug 19 20:19:44 ark start-web[269884]:     at async writeToCacheDir (/nix/store/vmd7bl6qhvkndgp4bf37az9s26m0vw3g-karakeep-0.24.1/lib/karakeep/apps/web/.next/standalone/node_modules/next/dist/server/image-optimizer.js:178:5)
  # Aug 19 20:19:44 ark start-web[269884]:     at async ImageOptimizerCache.set (/nix/store/vmd7bl6qhvkndgp4bf37az9s26m0vw3g-karakeep-0.24.1/lib/karakeep/apps/web/.next/standalone/node_modules/next/dist/server/image-optimizer.js:451:13)
  # Aug 19 20:19:44 ark start-web[269884]:     at async /nix/store/vmd7bl6qhvkndgp4bf37az9s26m0vw3g-karakeep-0.24.1/lib/karakeep/apps/web/.next/standalone/node_modules/next/dist/server/response-cache/index.js:121:25
  # Aug 19 20:19:44 ark start-web[269884]:     at async /nix/store/vmd7bl6qhvkndgp4bf37az9s26m0vw3g-karakeep-0.24.1/lib/karakeep/apps/web/.next/standalone/node_modules/next/dist/lib/batcher.js:45:32 {
  # Aug 19 20:19:44 ark start-web[269884]:   errno: -2,
  # Aug 19 20:19:44 ark start-web[269884]:   code: 'ENOENT',
  # Aug 19 20:19:44 ark start-web[269884]:   syscall: 'mkdir',
  # Aug 19 20:19:44 ark start-web[269884]:   path: '/nix/store/vmd7bl6qhvkndgp4bf37az9s26m0vw3g-karakeep-0.24.1/lib/karakeep/apps/web/.next/standalone/apps/web/.next/cache'
  # Aug 19 20:19:44 ark start-web[269884]: }
  #
  # So in postInstall just symlink that next.js crap's idea of cache to /tmp.
  #
  # Is this the "right" fix? hell no probably not but whatever I got other crap to do.
  karakeep = super.karakeep.overrideAttrs (old: {
    postInstall = ''
      mkdir -p $out/lib/karakeep/apps/web/.next/standalone/apps/web/.next
      ln -sf /tmp $out/lib/karakeep/apps/web/.next/standalone/apps/web/.next/cache
    '';
  });
  # rm -rf $out/lib/karakeep/node_modules/{@next,next,@swc,react-native,monaco-editor,faker,@typescript-eslint,@microsoft,@typescript-eslint,pdfjs-dist}
  # mkdir '/nix/store/vmd7bl6qhvkndgp4bf37az9s26m0vw3g-karakeep-0.24.1/lib/karakeep/apps/web/.next/standalone/apps/web/.next/cache'

  ipatool = super.ipatool.overrideAttrs (old: rec {
    version = "2.2.0";
    vendorHash = "sha256-f6mXTePiM5kZUdrYqvbN5pyNp1OGNMeJZMUJ3pvaRrc=";
    src = super.fetchFromGitHub {
      owner = "majd";
      repo = "ipatool";
      rev = "v${version}";
      hash = "sha256-z6f5PNxAH+8mS2kWjhST0LFhwTR01m7rR5O95ee+p2E=";
    };

    # If I don't do this version here seems to be from old.version somehow...
    # So cheat and just pass another -X into the build system.
    ldflags = old.ldflags ++ [
      "-X github.com/majd/ipatool/v2/cmd.version=${version}"
    ];
    latest = "curl --silent https://api.github.com/repos/majd/ipatool/tags | jq -r '.[] | .name' | grep -Ev rc | head -n 1 | tr -d v";
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
        ]
        ++ old.disabledTests;
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
