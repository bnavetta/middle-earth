/*

Ephemeral-by-default storage (AKA "impermanence", "Erase Your Darlings", or "tmpfs as root")

This configures ZFS and the impermanence NixOS module. I'm mostly using the same convention
as Erase Your Darlings:
- The rpool/local dataset is not backed up, while rpool/safe is (well, could be once I get to it)
- /nix is on its own dataset, rpool/local/nix
However, the /persist hierarchy has two datasets: /persist/local and /persist/safe
*/
{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.middle-earth.state;
in {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  options = {
    middle-earth.state = {
      impermanence = mkEnableOption "Ephemeral root storage";

      rootfsSize = mkOption {
        type = types.str;
        default = "1G";
        example = "1G";
        description = "Size of the root temporary filesystem";
      };
    };
  };

  config = mkIf cfg.impermanence {
    boot.zfs.forceImportRoot = false;
    boot.zfs.forceImportAll = false;
    boot.initrd.supportedFilesystems = ["zfs"];
    boot.supportedFilesystems = ["zfs"];
    # Ensure that we're always using a ZFS-compatible kernel
    boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    ################
    # File Systems #
    ################

    # TODO: assert that these are in the hardware-specific config? to support disko, etc.

    fileSystems."/efi".neededForBoot = true;
    fileSystems."/nix".neededForBoot = true;
    fileSystems."/persist/local".neededForBoot = true;
    fileSystems."/persist/safe".neededForBoot = true;

    /*

    fileSystems."/nix" = {
      device = "rpool/local/nix";
      fsType = "zfs";
      options = ["relatime" "zfsutil" "X-Mount.mkdir"];
      neededForBoot = true;
    };

    fileSystems."/persist/local" = {
      device = "rpool/local/persist";
      fsType = "zfs";
      options = ["relatime" "zfsutil" "X-Mount.mkdir"];
      neededForBoot = true;
    };

    fileSystems."/persist/safe" = {
      device = "rpool/safe/persist";
      fsType = "zfs";
      options = ["relatime" "zfsutil" "X-Mount.mkdir"];
      neededForBoot = true;
    };

    */

    ############################
    # Default Persistent State #
    ############################

    environment.persistence."/persist/local" = {
      hideMounts = true;

      directories = [
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/systemd/coredump"
      ];
    };

    environment.persistence."/persist/safe" = {
      directories = [
        "/var/lib/acme"
      ];

      files = [
        "/etc/machine-id"
        {
          file = "/etc/age/identity.txt";
          parentDirectory = {mode = "u=rwx,g=,o=";};
        }
      ];
    };

    services.openssh.hostKeys = [
      {
        path = "/persist/safe/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/persist/safe/ssh/ssh_host_rsa_key";
        type = "rsa";
      }
    ];
  };
}
