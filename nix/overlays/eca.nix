{ inputs }:
self: super:
let
  mylib = import ../lib.nix { inherit (super) lib; };
  enableFullBuild = mylib.enableFullBuild super.stdenv.hostPlatform.system;
in
if enableFullBuild then
  {
    # Expose eca package when doing native builds
    eca = inputs.eca.packages.${super.system}.default;
  }
else
  {
    # Provide a dummy eca during cross-evaluation for flake check
    # This will cause emacs overlay to fail if it actually tries to build,
    # but flake check won't get that far
    eca = super.emptyDirectory;
  }
