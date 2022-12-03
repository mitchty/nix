{ config, age, ... }: {
  # TODO: Here for now only due to .netrc being used for git pull/push/clone
  # operations on say github. Probably best to put it "somewhere else".
  home.file.".netrc".source = config.lib.file.mkOutOfStoreSymlink age.secrets."git/netrc".path;
  home.file.".gh-cli-pub".source = config.lib.file.mkOutOfStoreSymlink age.secrets."git/gh-cli-pub".path;
  home.file.".gitignore".source = ../../static/git/ignore;

  # TODO: This is just a quick hack to get git config setup for now. Future me
  # make sure there isn't a programs.git or make this whole thing a module...
  home.file.".gitconfig-work".text = ''

    [user]
      name = Mitchell Tishmack
      email = mitchell.james.tishmack@hpe.com
  '';

  home.file.".gitconfig".text = (builtins.readFile ../../static/git/config) + ''
    # it worked
        [includeIf "gitdir:~/src/wrk/"]
           path = .gitconfig-work
  '';
}
