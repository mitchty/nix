self: super: rec {
  # This is my complicated af overlay for emacs
  #
  # The overall situation is I've hit issues with using org mode init files with the overlay.
  #
  # So this overlay defines a set of derivations that do:
  # - "compiles/tangles" the org mode file to .el directly
  # - uses ^^^^ to ensure the patched emacs I have can run in case I eff up missing a ) somewhere. Not that that eeeever happens
  # - TODO: tests out that tree-sitter et al work with the config by batch loading the .org file itself, not nixpkgs 23.11 seems to have me seg faulting for some reason
  #
  # The latter TODO is the "real" reason for this overlay if I'm honest
  #

  # Shared config overrideattr'd in with other derivations not really useful on
  # its own, well not intended to be by me at least.
  emacsShared = super.emacs29.override {
    withSQLite3 = true;
    withWebP = true;
    withImageMagick = true;
    withTreeSitter = true;
  };

  # Patched emacs-overlay for each platform I care about e.g. linux/macos
  emacsPatched =
    # I yeet a lot of patches at the nextstep darwin build of emacs cause the
    # defaults kinda ass so we want to improve it slightly.
    if super.hostPlatform.isDarwin then
      emacsShared.overrideAttrs
        (old: {
          # bit old mostly off this https://github.com/NixOS/nixpkgs/issues/12863 assume its been fixed but should find out.
          # TODO: still needed?
          preConfigure = ''
            sed -i -e 's/headerpad_extra=1000/headerpad_extra=2000/' configure.ac
            autoreconf
          '';
          configureFlags = old.configureFlags ++ [
            "--disable-build-details"
            "--with-modules"
            "--with-native-comp"
            "--with-natural-title-bar"
          ];

          patches =
            (old.patches or [ ])
            ++ [
              # Fixes incorrect window role in macos
              (super.fetchpatch {
                url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-28/fix-window-role.patch";
                sha256 = "+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
              })
              # Use poll instead of select to get file descriptors
              (super.fetchpatch {
                url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-29/poll.patch";
                sha256 = "jN9MlD8/ZrnLuP2/HUXXEVVd6A+aRZNYFdZF8ReJGfY=";
              })
              # TESTING: Add setting to enable rounded window with no decoration (still have to alter default-frame-alist)
              (super.fetchpatch {
                url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-30/round-undecorated-frame.patch";
                sha256 = "uYIxNTyfbprx5mCqMNFVrBcLeo+8e21qmBE3lpcnd+4=";
              })
              # Make Emacs aware of OS-level light/dark mode
              # https://github.com/d12frosted/homebrew-emacs-plus#system-appearance-change
              (super.fetchpatch {
                url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-28/system-appearance.patch";
                sha256 = "oM6fXdXCWVcBnNrzXmF0ZMdp8j0pzkLE66WteeCutv8=";
              })
            ];
        })
    else # basically everything else, for now this means linux
      (emacsShared.override {
        withX = true;
        withGTK3 = true;
        withXinput2 = true;
      }).overrideAttrs (_: {
        configureFlags = [
          "--disable-build-details"
          "--with-modules"
          "--with-x-toolkit=gtk3"
          "--with-xft"
          "--with-cairo"
          "--with-xaw3d"
          "--with-native-compilation"
          "--with-imagemagick"
          "--with-xinput2"
        ];
      });

  mtEmacsPrime = super.emacsWithPackagesFromUsePackage
    {
      config = ../static/emacs/init.org;
      package = emacsPatched;
      # if pkgs.hostPlatform.isDarwin then
      # inputs.nixpkgs-darwin-old.legacyPackages.${pkgs.system}.emacs29
      # else
      # inputs.nixpkgs.legacyPackages.${pkgs.system}.emacs29;
    };

  # A lot of this exists due to this:
  # https://github.com/nix-community/emacs-overlay/issues/373
  #
  # So have emacs tangle the .el file for us so we can use that to pass into the
  # overlay function.
  #
  # While I'm at it, lets also use the build phase here to ensure that the
  # entire derivation works or if I forgot a ) somewhere... again...
  #
  #
  init-el = super.stdenv.mkDerivation
    rec {
      pname = "initel";
      version = "0.0.0";
      buildInputs = [
        self.mtEmacsPrime
      ];
      src = ../static/emacs;

      # abuse this derivation to munge org->el so we can use that for default init file
      # and then also use that to batch load it.
      buildPhase = ''
        set -e
        emacs -Q --batch --eval "
            (progn
              (require 'ob-tangle)
              (dolist (file command-line-args-left)
                (with-current-buffer (find-file-noselect file)
                  (org-babel-tangle))))
          " init.org
        export HOME=$TMPDIR
        echo emacs batch load to make sure init.el is parseable >&2
        emacs -nw --batch --debug-init --load init.el

        echo emacs batch load init.el with itself to make sure all of the config works with modes >&2
        emacs -nw --batch --debug-init --load init.el init.el
      '';

      installPhase = ''
        install -dm755 $out
        install -m644 init.org $out/init.org
        install -m644 init.el $out/init.el
      '';
    };

  # me emacs all wrapped up in one
  emacsMt = super.emacsWithPackagesFromUsePackage
    {
      # TODO: maybe make this a parameter to pass in and default to the git
      # branch upstream emacs29? Note I've had every version of emacs fail to
      # load on macos 23.11 with tree sitter with a segfaul so I dunno anymore
      # I'm betting it'll be somethign like gcc or llvm thats at fault.
      package = emacsPatched;
      defaultInitFile = true;
      config = "${self.init-el}/init.el";
      #      package = super.emacs29;
      # TODO: figure out what broke in darwin 23.11 and tweak lto et al?
      # package = super.emacsGcc.override {
      #   libgccjit = super.gcc9.cc.override {
      #     name = "libgccjit";
      #     langFortran = false;
      #     langCC = false;
      #     langC = false;
      #     profiledCompiler = false;
      #     langJit = true;
      #     enableLTO = false;
      #   };
      # };

      # If for some reason I need to override an emacs package
      # override = epkgs: epkgs // {
      #   ligature = epkgs.trivialBuild { pname = "ligature"; src = sources.emacs-ligature; };
      # });
    };
  # extraEmacsPackages = with epkgs; [
  #   use-package
  #   org-plus-contrib
  # ];

  # Patches I'm applying to stock emacs 29. This is also to stay at tip of emacs 29 development.
  #        (final: prev: {
  #          emacs29 = prev.emacs-git.overrideAttrs
  #            (old: {
  #              name = "emacs29";
  #              version = emacs-upstream.shortRev;
  #              src = emacs-upstream;
  #            });
  #            emacs29-patched = final.emacs29.overrideAttrs
  #            (super: {
  #              # buildInputs = super.buildInputs ++
  #              #   nixpkgs.lib.attrsets.attrVals [
  #              #     "Cocoa"
  #              #     "WebKit"
  #              #   ]
  #              #     nixpkgs-darwin.legacyPackages.x86_64-darwin.apple_sdk.frameworks;
  #              preConfigure = ''
  #                sed -i -e 's/headerpad_extra=1000/headerpad_extra=2000/' configure.ac
  #                autoreconf
  #              '';
  #              configureFlags = super.configureFlags ++ [
  #                # "--with-native-comp"
  #                # "--with-xwidgets"
  #                "--with-natural-title-bar"
  #              ];
  #              patches = [
  #                # (prev.fetchpatch {
  #                #   name = "mac-gui-loop-block-lifetime";
  #                #   url = "https://raw.githubusercontent.com/jwiegley/nix-config/90086414208c3a4dc2f614af5a0dd0c1311f7c6d/overlays/emacs/0001-mac-gui-loop-block-lifetime.patch";
  #                #   sha256 = "sha256-HqcRxXfZB9LDemkC7ThNfHuSHc5H5B2MQ102ZyifVYM=";
  #                # })
  #                # (prev.fetchpatch {
  #                #   name = "mac-gui-loop-block-autorelease";
  #                #   url = "https://raw.githubusercontent.com/jwiegley/nix-config/90086414208c3a4dc2f614af5a0dd0c1311f7c6d/overlays/emacs/0002-mac-gui-loop-block-autorelease.patch";
  #                #   sha256 = "sha256-CBELVTAWwgaXrnkTzMsYH9R18qBnFBFHMOaVeC/F+I8=";
  #                # })
  #                (prev.fetchpatch {
  #                  name = "gc-block-align-patch";
  #                  url = "https://github.com/tyler-dodge/emacs/commit/36d2a8d5a4f741ae99540e139fff2621bbacfbaa.patch";
  #                  sha256 = "sha256-/hJa8LIqaAutny6RX/x6a+VNpNET86So9xE8zdh27p8=";
  #                })
  #                # (prev.fetchpatch {
  #                #   name = "buffer-process-output-on-thread-patch";
  #                #   url = "https://github.com/emacs-mirror/emacs/commit/b386047f311af495963ad6a25ddda128acc1d461.patch";
  #                #   sha256 = "sha256-dRkiowEtu/oOLh29/b7VSXGKsV5qE0PxMWrox5/LRoM=";
  #                # })
  #                # (prev.fetchpatch {
  #                #   name = "immediate-output-notification-patch";
  #                #   url = "https://github.com/emacs-mirror/emacs/commit/3f49c824f23b2fa4ce5512f80abdb0888a73c4a1.patch";
  #                #   sha256 = "sha256-ShQsS9ixc15cyrPGYDLxbbsgySK4JUuCSqk6+XE0U4Q=";
  #                # })
  #                ./patches/emacs-use-correct-window-role.patch
  #              ];
  #            });
  #        })

}
