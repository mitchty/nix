final: prev:
let
  owner = "ggml-org";
  repo = "llama.cpp";
in
{
  llama-cpp = prev.llama-cpp.overrideAttrs (old: rec {
    version = "8233";

    src = prev.fetchFromGitHub {
      inherit owner repo;
      tag = "b${version}";
      hash = "sha256-EZILxBFUVqLNPwQpes7BujciXt+BUrNIObrFgABkkPM=";
      leaveDotGit = true;
      postFetch = ''
        git -C "$out" rev-parse --short HEAD > $out/COMMIT
        find "$out" -name .git -print0 | xargs -0 rm -rf
      '';
    };

    npmDepsHash = "sha256-5ZswgZFLeI32/xQZqCTTFbCzleDqr5AotjFg/5rNn1M=";

    meta = old.meta // {
      homepage = "https://github.com/${owner}/${repo}";
    };

    latest = ''
      curl -s "https://api.github.com/repos/${owner}/${repo}/git/refs/tags" | jq -r '.[] | select(.ref | startswith("refs/tags/b")) | .ref | sub("refs/tags/"; "")' | tail -n1 | tr -d b
    '';
  });
}
