# Profile to set up Secure Boot via Lanzaboote
{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  boot = {
    bootspec.enable = true;

    # Disable both GRUB and systemd-boot
    loader.grub.device = "nodev";
    loader.systemd-boot.enable = false;
    loader.efi.canTouchEfiVariables = true;

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };

  environment.systemPackages = [pkgs.sbctl];
}
