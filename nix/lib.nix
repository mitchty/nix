{ lib, ... }:
rec {
  # Fetch a model file from HuggingFace. Takes pkgs first, then the spec attrset.
  # Spec attrs: owner, repo, name, hash (optional), branch (optional, default "main")
  fetchhf =
    pkgs:
    {
      owner,
      repo,
      branch ? "main",
      name,
      hash ? "",
      ...
    }@args:
    pkgs.fetchurl (
      (builtins.removeAttrs args [
        "owner"
        "repo"
        "branch"
      ])
      // {
        url = "https://huggingface.co/${owner}/${repo}/resolve/${branch}/${name}";
        inherit name;
      }
      // lib.optionalAttrs (hash != "") { inherit hash; }
    );

  # Raw model specs — no pkgs involved, just metadata.
  # Modules pick the ones they want and call fetchhf pkgs spec to materialise.
  llamaModels = {
    flux2 = {
      owner = "unsloth";
      repo = "FLUX.2-klein-9B-GGUF";
      name = "flux-2-klein-9b-F16.gguf";
      hash = "sha256-WoiGr0jHTTmmk/iuem2b7a/SQxbDXTyZ5hEkMlrtu5g=";
    };
    minimax25 = {
      owner = "unsloth";
      repo = "MiniMax-M2.5-GGUF";
      name = "MiniMax-M2.5-UD-TQ1_0.gguf";
      hash = "sha256-YPxNL4z/Fn7jOfDtAMJ3GKHdid//AfIA33HcFe7nRy4=";
    };
    gemma3 = {
      owner = "ggml-org";
      repo = "gemma-3-4b-it-GGUF";
      name = "gemma-3-4b-it-Q4_K_M.gguf";
      hash = "sha256-iC6NLbRNxVT7DqUHfLfkvEnnNCofDaV5AcCALqIaCGM=";
    };
    llava = {
      owner = "cjpais";
      repo = "llava-1.6-mistral-7b-gguf";
      name = "llava-v1.6-mistral-7b.Q6_K.gguf";
      hash = "sha256-MYJhcP+i6AgLvNdMrHGPkGSE/VpZiVVQ75TBuqSZdZU=";
    };
    qwen3 = {
      owner = "bartowski";
      repo = "Qwen_Qwen3-0.6B-GGUF";
      name = "Qwen_Qwen3-0.6B-Q4_K_M.gguf";
      hash = "sha256-ms/B4AExHzS0JSABtiby5GbVkqQgZfZlcb/zeQ1OGxQ=";
    };
    gpt-oss-20b = {
      owner = "ggml-org";
      repo = "gpt-oss-20b-GGUF";
      name = "gpt-oss-20b-mxfp4.gguf";
      hash = "sha256-vjemNqyg/BquDTIyX4L2tNIUlfBoI7X7wYmK4DA+mTU=";
    };
  };

  # Admin user SSH key for secrets decryption, the private key backing this is not stored anywhere
  adminKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILGJSGtoArRe0CMGOek5iZXOdLikEvrulvjVUXpx4jLV";
  hmKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGimTE2+hCBsFIAOxFUO3+hmTMfXb2e8iSObBNnUr/af";

  # Generate secrets.nix entries from host configuration data for mitchty.secrets
  mkSecretsFromConfigs =
    {
      nixosConfigs ? { },
      darwinConfigs ? { },
    }:
    let
      # Extract host metadata from a configuration
      # Fail-open if mitchty.secrets isn't defined or is incomplete, return null
      # cause apparently I forgot to add something OR didn't want a system to use this crap
      extractHostMeta =
        name: cfg:
        let
          meta = cfg.config.mitchty.secrets or null;
          hasKey = meta != null && meta ? hostKey && meta.hostKey != null && meta.hostKey != "";
        in
        if hasKey then
          {
            inherit name;
            key = meta.hostKey;
            tags = meta.tags or [ ];
          }
        else
          null;

      # Get all hosts from both NixOS and Darwin configurations
      allHosts = builtins.filter (x: x != null) (
        (lib.mapAttrsToList extractHostMeta nixosConfigs)
        ++ (lib.mapAttrsToList extractHostMeta darwinConfigs)
      );

      # Get hosts by tag strings
      hostsByTag = tag: map (h: h.key) (builtins.filter (h: builtins.elem tag h.tags) allHosts);

      # All host keys for that kindo o ting
      allHostKeys = map (h: h.key) allHosts;
    in
    {
      inherit allHosts allHostKeys;

      #      getTag = tag: hostsByTag tag;
      getTag = hostsByTag;

      # Generate publicKeys list for a secret, my admin ssh key gets yeeted on
      # here so I can change stuff around
      mkKeys =
        {
          tags ? [ ],
          hosts ? [ ],
        }:
        let
          taggedKeys = lib.flatten (map hostsByTag tags);

          # Keys from specific host names
          namedHosts = builtins.filter (h: builtins.elem h.name hosts) allHosts;
          namedKeys = map (h: h.key) namedHosts;

          # Combine and dedup
          combined = lib.unique (taggedKeys ++ namedKeys ++ [ adminKey ]);
        in
        combined;
    };

  # Detect if we're cross-evaluating (e.g., macOS evaluating Linux configs or vice versa)
  # Returns true if we should skip full builds to avoid cross-platform evaluation issues
  #
  # TODO: builtins.pathExists on non-store paths always returns false in Nix
  # flake pure eval mode (e.g. `nix eval --expr 'builtins.pathExists "/proc/kcore"'`
  # returns false even when the file physically exists). builtins.currentSystem is
  # similarly unavailable without --impure. So any runtime host-detection approach
  # is broken here. Hardcoded to false for now so enableFullBuild always returns
  # true; the macOS nix flake check cross-eval guard needs a different strategy.
  isCrossEvaluation = _targetSystem: false;

  # Helper to determine if we should do full builds (inverse of isCrossEvaluation)
  enableFullBuild = targetSystem: !(isCrossEvaluation targetSystem);

  # Reduce line count a bit to make flake.nix less yappy
  mkShellApp = name: scriptText: pkgs: {
    type = "app";

    # Keep nix warnings out so it doesn't bitch that there is a missing meta attribute.
    meta.description = "app for ${name}";
    program = "${
      pkgs.writeShellApplication {
        inherit name;
        text = ''
          set -e
          ${scriptText}
        '';
      }
    }/bin/${name}";
  };

  # I need to brain out how to have this only list files committed into git...
  mkPackageChecks =
    packagesDir: pkgs:
    let
      packageFiles = builtins.readDir packagesDir;

      validPackages = lib.filterAttrs (
        name: type: type == "regular" && lib.hasSuffix ".nix" name
      ) packageFiles;

      packageNames = map (name: lib.removeSuffix ".nix" name) (builtins.attrNames validPackages);

      # hack to filter out stuff that might not yet be committed or in the git stash
      existingPackages = builtins.filter (name: pkgs ? ${name}) packageNames;
    in
    lib.listToAttrs (
      map (name: {
        name = "package-${name}";
        value = pkgs.${name};
      }) existingPackages
    );

  # Function to be used for feature detection.
  hasFeature =
    file: featname:
    let
      contents = builtins.readFile file;
      lines = lib.splitString "\n" contents;
    in
    lib.any (line: lib.hasInfix featname line) lines;

  # Setup a cifs mount to the synology.
  mkCifsMount =
    {
      mountpoint,
      share,
      creds,
      uid ? 1000, # "mitch" uid
      gid ? 100, # "users" gid
      prefix ? "/nas",
      server ? "s1.home.arpa",
    }:
    {
      "${prefix}/${mountpoint}" = {
        device = "//${server}/${share}";
        fsType = "cifs";
        options = [
          # Common user options
          "user" # NB keep this above exec or you can't run scripts off this mount point
          "mfsymlinks"
          "exec"
          "nofail"
          "forceuid"
          "forcegid"
          "soft"
          "rw"
          "vers=3"
          "credentials=${creds}"
          # Automount related options
          "x-systemd.automount"
          "x-systemd.idle-timeout=300"
          "x-systemd.mount-timeout=60s"
          "nofail"
          # perf...ish options
          "bsize=8388608"
          "rsize=131072"
          #"cache=loose" # TODO need to test this between nodes
          # Who we're mounting this for
          "uid=${uid}"
          "gid=${gid}"
        ];
      };
    };
}
