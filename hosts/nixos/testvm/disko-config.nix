{disks ? ["/dev/vda"], ...}: let
  zfsFilesystem = mountpoint: {
    inherit mountpoint;
    zfs_type = "filesystem";
  };
in {
  disk.main = {
    device = builtins.elemAt disks 0;
    type = "disk";
    content = {
      type = "table";
      format = "gpt";
      partitions = [
        {
          type = "partition";
          name = "ESP";
          start = "0";
          end = "128MiB";
          fs-type = "fat32";
          bootable = true;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/efi";
          };
        }

        # TODO: swap?

        {
          type = "partition";
          name = "zfs";
          start = "128MiB";
          end = "100%";
          content = {
            type = "zfs";
            pool = "rpool";
          };
        }
      ];
    };
  };

  zpool.rpool = {
    type = "zpool";

    options = {
      # https://www.reddit.com/r/zfs/comments/nja14p/zfs_propertiestuning_for_nvme_storage_pool/
      ashift = "12";
      autotrim = "on";
      dedup = "off";
      xattr = "sa";
      acltype = "posixacl";
      atime = "on";
      relatime = "on";
      sync = "standard";
    };

    datasets = {
      local = {
        zfs_type = "filesystem";
        options.mountpoint = "none";
        options.canmount = "off";
      };

      safe = {
        zfs_type = "filesystem";
        options.mountpoint = "none";
        options.canmount = "off";
      };

      "local/nix" = zfsFilesystem "/nix";

      "local/persist" = zfsFilesystem "/persist/local";

      "safe/persist" = zfsFilesystem "/persist/safe";

      "safe/home" = zfsFilesystem "/home";
    };
  };

  nodev."/" = {
    fsType = "tmpfs";
    mountOptions = [
      "size=1G"
      "defaults"
      "mode=755"
    ];
  };
}
