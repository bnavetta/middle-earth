{
  inputs,
  cell,
}: let
  inherit (inputs) std;
  inherit (inputs.cells) base ben;

  # Host directory for microVM volumes
  volumeDir = "/home/ben/big/middle-earth/pippin";
in {
  pippin = std.lib.ops.mkMicrovm ({config, lib, ...}: {
    system.stateVersion = "23.05";
    networking.hostName = "pippin";

    # microvm.nix disables DRM by default
    # https://github.com/astro/microvm.nix/blob/5882c4da762d1d5414aaa599f8f671e58100bccf/nixos-modules/microvm/system.nix#L74
    boot.blacklistedKernelModules = lib.mkForce [ "rfkill" "intel_pstate" ];

    boot.kernelModules = ["drm" "virtio_gpu"];

    imports = [
      base.profiles.minimal
      base.profiles.desktop
      ben.profiles.nixos
    ];

    users.users.root.password = "root";
    users.users.sysadmin.password = "sysadmin";

    middle-earth.state.mode = "onefs";

    microvm = {
      hypervisor = "qemu";
      qemu.extraArgs = [
        "-device"
        "virtio-vga-gl"
        "-display"
        "sdl,gl=on"
        "-device"
        "qemu-xhci"
        "-device"
        "usb-mouse"
        "-device"
        "usb-kbd"
      ];

      # Ensure the volume directory exists on the host
      preStart = "mkdir -p ${volumeDir}";

      volumes = [
        {
          mountPoint = "/persist";
          image = "${volumeDir}/persist.img";
          size = 512;
          fsType = "ext4";
        }
        {
          # Having a writable overlay for /nix/store allows installing packages inside the VM
          image = "${volumeDir}/nix-store-overlay.img";
          mountPoint = config.microvm.writableStoreOverlay;
          size = 512;
        }
      ];

      # Speed up builds by mounting the host filesystem read-only
      shares = [
        {
          tag = "ro-store";
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
        }
      ];
    };
  });
}
