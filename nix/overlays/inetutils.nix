self: super: {
  # Gnu being gnu again, this time llvm with -Werror is never tested against and
  # they're butthurt about anything non gnu and refusing to fix anything.
  #
  # At one point gnu used to be quality now its just a cult.
  # https://lists.gnu.org/r/bug-gnulib/2025-06/msg00327.html
  #
  # This is really only for darwin but whatever its fine for now.
  inetutils = super.inetutils.overrideAttrs (attrs: {
    # Disable -Werror for clang builds (macOS)
    # GNU upstream doesn't test with clang and refuses to fix warnings
    # NIX_CFLAGS_COMPILE = (attrs.NIX_CFLAGS_COMPILE or [ ]) ++ [
    #   "-Wno-error"
    #   "-wnoformat-security"
    # ];
  });
}
