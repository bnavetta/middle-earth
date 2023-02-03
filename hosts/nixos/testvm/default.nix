{
  suites,
  profiles,
  pkgs,
  lib,
  inputs,
  ...
}: {
  system.stateVersion = "23.05";

  imports = suites.desktop;

  # Must be set for ZFS
  networking.hostId = "c30a0615";

  # testvm
  # users.users.root.hashedPassword = "$y$j9T$CkBt9droMLsowPFgmejj50$Da/O0NTOH1QNpij4XhA.6rWYs0CKHdHPnWi68CvIUxB";
  # users.users.sysadmin.hashedPassword = "$y$j9T$CkBt9droMLsowPFgmejj50$Da/O0NTOH1QNpij4XhA.6rWYs0CKHdHPnWi68CvIUxB";

  middle-earth.networking.expectedInterfaces = [
    "eth0"
  ];

  boot.kernelModules = ["virtio_gpu" "virtio_vga"];
  hardware.opengl.extraPackages = [pkgs.virglrenderer];

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Ensure this uses QEMU built with OpenGL support
  virtualisation.qemu.package = pkgs.qemu.override {
    guestAgentSupport = true;
    sdlSupport = true;
    gtkSupport = true;
    openGLSupport = true;
    virglSupport = true;
  };

  virtualisation.qemu.options = [
    # TODO: QEMU OpenGL doesn't quite work with NVIDIA? https://github.com/NixOS/nixpkgs/issues/164436
    # and sway is generally iffy with virtualized GPUs: https://github.com/swaywm/sway/issues/5834
    "-vga none"
    "-device virtio-vga-gl"
    "-display gtk,gl=on"
    "-cpu host"
    # "-vga none" "-device virtio-vga" "-display gtk"
    #"-vga none" "-device virtio-gpu-pci"
    # "-vga virtio"
    # "-vga qxl"
  ];

  # Enable limited DRM debugging
  boot.kernelParams = ["drm.debug=0x1c"];
}
