{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    inputs.agenix.darwinModules.age
  ];

  age.secrets = {
    "git/netrc" = {
      file = ../../secrets/git/netrc.age;
      owner = "mitch";
    };
    "git/gh-cli-pub" = {
      file = ../../secrets/git/gh-cli-pub.age;
      owner = "mitch";
    };
  };
}
