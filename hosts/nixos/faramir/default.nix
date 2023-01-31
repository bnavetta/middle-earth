{
  suites,
  profiles,
  pkgs,
  lib,
  inputs,
  ...
}: {
  system.stateVersion = "23.05";

  imports =
    suites.base
    ++ [
      inputs.nixos-hardware.nixosModules.raspberry-pi-4
      profiles.lan
      ./hardware-configuration.nix
    ];

  # Enable GPU acceleration
  hardware.raspberry-pi."4".fkms-3d.enable = true;
}
