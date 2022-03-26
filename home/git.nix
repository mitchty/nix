{ ... }: {
  # TODO: This is just a quick hack to get git config setup for now. Future me
  # make sure there isn't a programs.git
  home.file.".gitconfig".source = ../static/git/config;
  home.file.".gitignore".source = ../static/git/ignore;
}
