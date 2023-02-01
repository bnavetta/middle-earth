{
  suites,
  profiles,
  pkgs,
  lib,
  inputs,
  ...
}: {
  system.stateVersion = "23.05";

  imports = suites.server ++ [./hardware-configuration.nix ./networking.nix];
}
