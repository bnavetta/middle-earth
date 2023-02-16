{
  inputs,
  cell,
}: let
  inherit (inputs.cells) base ben lib;
in {
  elessar = lib.lib.mkSystem {
    name = "elessar";
    system = "x86_64-linux";
    modules = [
      {
        system.stateVersion = "23.05";

        networking.hostId = "0b8a8daa";

        fileSystems."/efi" = {
          device = "/dev/nvme0n1p2";
          fsType = "vfat";
          neededForBoot = true;
        };
        
        # Ensure the NVMe kernel module is in the initrd
        boot.initrd.availableKernelModules = [ "nvme" ];

        # Despite the name, this works for Wayland too
        services.xserver.videoDrivers = ["nvidia"];

        # Set up for running aarch64 binaries with QEMU, including for Nix cross-builds to a Raspberry Pi
        # This also supports x86_64-windows, would that cover Wine?
        # boot.binfmt.emulatedSystems = ["aarch64-linux"];

        # Monitor UPS state
        power.ups.enable = true;
        power.ups.mode = "standalone";
        # According to https://github.com/NixOS/nixpkgs/blob/c43f676c938662072772339be6269226c77b51b8/nixos/modules/services/monitoring/ups.nix#L231-L238,
        # this file is sensitive... TBD what's supposed to be in it
        environment.etc."nut/upsd.conf".source = "";

        # Colmena setup
        deployment = {
          tags = ["local" "desktop"];
          allowLocalDeployment = true;
          targetHost = "elessar.local";
        };
      }
      base.profiles.default
      base.profiles.desktop
      base.profiles.development
      base.profiles.lan
      ben.profiles.nixos
    ];

    meta.description = "NixOS desktop";
  };
}
