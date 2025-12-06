{ lib, ... }:
{
  # Detect if we're evaluating a Linux config on macOS (e.g., during nix flake check on macOS)
  # This happens when the host platform appears to be Linux but we're actually running on macOS
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
