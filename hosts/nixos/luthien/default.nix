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

  middle-earth.networking.expectedInterfaces = ["eth0" "eth1"];
}
