_: {
  home.file = {
    ".stignore".text = ''
      #include .stglobalignore
    '';
    ".stglobalignore".text = builtins.readFile ../../static/home/stglobalignore;
  };
}
