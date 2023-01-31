{
  suites,
  profiles,
  pkgs,
  lib,
  inputs,
  ...
}: {
  system.stateVersion = "23.05";

  imports = suites.base ++ [./hardware-configuration.nix ./networking.nix];
}
