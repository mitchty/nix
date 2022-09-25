{ ... }: {
  home.file = {
    ".stignore".text = ''
      #include .stglobalignore
    '';
    ".stglobalignore".text = (builtins.readFile ./stglobalignore);
  };
}
