targetSystem:
let
  onMacos = builtins.pathExists "/System/Library";
  onLinux = builtins.pathExists "/proc/kcore";

  targetIsDarwin = builtins.elem targetSystem [
    "aarch64-darwin"
    "x86_64-darwin"
  ];
  # Are we cross-evaluating? (macOS -> Linux or Linux -> macOS)
  isCrossEvaluation = onMacos != onLinux;

  # System-specific defaults for native evaluation
  nativeDefaults = {
    "x86_64-linux" = true;
    "i686-linux" = true;
    "aarch64-darwin" = false;
  };
in
# If cross-evaluating, disable full builds
# Otherwise, use system-specific defaults
if isCrossEvaluation then false else nativeDefaults.${targetSystem} or true
# #if isCrossEvaluation then false else nativeDefaults.${targetSystem}
# true
