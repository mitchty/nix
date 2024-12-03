self: super: rec {
  open-webui = super.open-webui.overrideAttrs (old: {
    dependencies = old.dependencies ++ [ super.python311Packages.emoji ];
  });
}
