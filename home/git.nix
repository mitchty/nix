{ ... }: {
  # TODO: This is just a quick hack to get git config setup for now. Future me
  # make sure there isn't a programs.git
  home.file.".gitconfig".source = ./.gitconfig;
  home.file.".gitignore".source = ./.gitignore;
}
