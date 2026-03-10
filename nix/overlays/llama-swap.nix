final: prev:
let
  owner = "mostlygeek";
  repo = "llama-swap";
in
{
  llama-swap = prev.llama-swap.overrideAttrs (old: rec {
    version = "197";

    src = prev.fetchFromGitHub {
      inherit owner repo;
      tag = "v${version}";
      hash = "sha256-EXgyYmpbN/zzr6KeSpvFEB+FS7gDIZFinNMv70v5boY=";
      leaveDotGit = true;
      postFetch = ''
        cd "$out"
        git rev-parse HEAD > $out/COMMIT
        # '0000-00-00T00:00:00Z'
        date -u -d "@$(git log -1 --pretty=%ct)" "+'%Y-%m-%dT%H:%M:%SZ'" > $out/SOURCE_DATE_EPOCH
        find "$out" -name .git -print0 | xargs -0 rm -rf
      '';
    };

    # Directory changed from 'ui' to 'ui-svelte' in v...something who cares
    # Need to set both sourceRoot AND override the npmDeps derivation
    passthru = old.passthru // {
      ui = old.passthru.ui.overrideAttrs (uiOld: {
        inherit src; # Use the updated source
        sourceRoot = "source/ui-svelte";
        npmDeps = prev.fetchNpmDeps {
          inherit src;
          sourceRoot = "source/ui-svelte";
          name = "llama-swap-ui-${version}-npm-deps";
          hash = "sha256-Fs7+JKE8YBp2Xj8bVBlwmT+UwuD642VeUHiPx+fv94c=";
        };
      });
    };

    vendorHash = "sha256-XiDYlw/byu8CWvg4KSPC7m8PGCZXtp08Y1velx4BR8U=";

    # Disable tests - they fail in the build sandbox, too many network using tests.
    doCheck = false;

    meta = old.meta // {
      homepage = "https://github.com/${owner}/${repo}";
    };

    latest = "curl --silent https://api.github.com/repos/${owner}/${repo}/tags | jq -r '.[].name' | sed 's/^v//' | head -n 1";
  });
}
