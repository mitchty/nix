{ ... }: {
  home.file = {
    ".stignore".text = ''
      #include .stglobalignore
    '';
    ".stglobalignore".text = ''
      .git/COMMIT_EDITMSG
      (?d).DS_Store
      packer_cache
      result
      target/release
      target/debug
      domain/attic
      tmp_pack_*
    '';
  };
}
