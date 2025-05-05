{ lib, ... }:

{
  # For debugging purposes keep the current flake used to construct things into
  # /etc
  environment.etc."current-flake".source = ./../..;
}
