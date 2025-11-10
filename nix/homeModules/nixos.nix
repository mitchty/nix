{
  inputs,
  ...
}:
{
  imports = with inputs.self.homeModules; [ common ];

  home = {
    stateVersion = "24.11";
  };

  # programs = mapAttrs (_: v: v // { enable = true; }) {
  # };
}
