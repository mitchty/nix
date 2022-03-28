{ config, lib, pkgs, age, ... }: {
  # TODO: This is just a quick hack to get git config setup for now. Future me
  # make sure there isn't a programs.git
  home.file.".gitconfig".source = ../static/git/config;
  home.file.".gitignore".source = ../static/git/ignore;

  # TODO: Here for now only due to .netrc being used for git pull/push/clone
  # operations on say github. Probably best to put it "somewhere else".
  home.file.".netrc".source = config.lib.file.mkOutOfStoreSymlink age.secrets."git/netrc".path;
}
