{ modulesPath, ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  # Use a ramdisk for /tmp to reduce wear on the SD card
  # This is disabled because my 1GB-of-RAM Raspberry Pi becomes unusable when trying to build Nix derivations
  boot.tmpOnTmpfs = true;
}
