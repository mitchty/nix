self: super: {
  # Until this stuff is fixed, add this patch to fix things for ctranslate2
  # https://github.com/NixOS/nixpkgs/issues/445447
  # https://github.com/NixOS/nixpkgs/pull/450313
  ctranslate2 = super.ctranslate2.overrideAttrs (old: {
    patches = [
      (super.fetchurl {
        url = "https://raw.githubusercontent.com/NixOS/nixpkgs/51640275eb64be2906a40efd78fbbff0f4e0030a/pkgs/by-name/ct/ctranslate2/cmake-3.10.patch";
        sha256 = "sha256-eSxZf32AjFWuSIwXIZDS+5Jrj7E2dxFXFE7Hct4pTsQ=";
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

  # plex = super.plex.overrideAttrs (_: rec {
  #   version = "1.42.1.10060-4e8b05daf";

  #   src = super.fetchurl {
  #     url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
  #     sha256 = "3a822dbc6d08a6050a959d099b30dcd96a8cb7266b94d085ecc0a750aa8197f4";
  #   };
  # });

  pythonPackagesExtensions = super.pythonPackagesExtensions ++ [
    (pyfinal: pyprev: {
      rapidocr-onnxruntime = pyprev.rapidocr-onnxruntime.overridePythonAttrs (old: {
        doCheck = false;
      });
    })
  ];
}
