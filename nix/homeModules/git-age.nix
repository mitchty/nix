{ config, ... }:
{

  age.secrets = {
    "secrets/git/netrc" = {
      file = ../../secrets/git/netrc.age;
      path = config.home.homeDirectory + "/.netrc";
    };
    "secrets/git/gh-cli-pub" = {
      file = ../../secrets/git/gh-cli-pub.age;
      path = config.home.homeDirectory + "/.gh-cli-pub";
    };
  };

}
