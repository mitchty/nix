{ config, age, ... }: {
  # TODO: Here for now only due to .netrc being used for git pull/push/clone
  # operations on say github. Probably best to put it "somewhere else".
  home.file.".netrc".source = config.lib.file.mkOutOfStoreSymlink age.secrets."git/netrc".path;
  home.file.".gitignore".source = ../../static/git/ignore;
  home.file.".gitconfig".source = ../../static/git/config;
}
