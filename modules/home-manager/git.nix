{ config, age, ... }: {
  # TODO: Here for now only due to .netrc being used for git pull/push/clone
  # operations on say github. Probably best to put it "somewhere else".
  home.file.".netrc".source = config.lib.file.mkOutOfStoreSymlink age.secrets."git/netrc".path;
  home.file.".gh-cli-pub".source = config.lib.file.mkOutOfStoreSymlink age.secrets."git/gh-cli-pub".path;
  home.file.".gitignore".source = ../../static/git/ignore;
  home.file.".gitconfig-work".source = ../../static/git/config-work;
  home.file.".gitconfig".text = (builtins.readFile ../../static/git/config) + (builtins.readFile ../../static/git/config-work-include);
}
