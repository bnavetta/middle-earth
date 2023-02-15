{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.middle-earth.boot;
  espDir = "/efi";
in {
  options = {
    middle-earth.boot = {
      secureBoot = lib.mkEnableOption "Secure Boot";
    };
  };

  config = {
    assertions = [
      {
        assertion = !cfg.secureBoot;
        message = "SecureBoot support isn't implemented yet";
      }

      {
        assertion = pkgs.system == "x86_64-linux";
        message = "Bootloader configuration is only supported on x86-64 Linux with UEFI";
      }

      {
        # Don't make too many assumptions about disk layout, just that ESP exists
        assertion = (builtins.hasAttr espDir config.fileSystems) && config.fileSystems.${espDir}.neededForBoot;
        message = "EFI System Partition must exist at ${espDir} and have neededForBoot = true";
      }
    ];

    environment.systemPackages = with pkgs; [mokutil sbctl];

    boot.loader = {
      grub.enable = false;

      # TODO: will need to toggle between this and lanzaboote
      systemd-boot.enable = true;
      systemd-boot.memtest86.enable = true;

      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = espDir;
    };
  };
}
