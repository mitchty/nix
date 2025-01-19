{ config, lib, ... }:

with lib;
{
  services.fwupd.enable = true;
}
