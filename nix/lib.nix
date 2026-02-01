{ lib, ... }:
rec {
  # Admin user SSH key for secrets decryption, the private key backing this is not stored anywhere
  adminKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILGJSGtoArRe0CMGOek5iZXOdLikEvrulvjVUXpx4jLV";

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

  # This is a HUGE hack to work around nix flake check on macos nix and my emacs derivation of DOOOM
  isCrossPlatformEval = pkgs: pkgs.stdenv.hostPlatform.isLinux && builtins.pathExists /System/Library;

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
