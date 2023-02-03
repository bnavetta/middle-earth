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
    "-vga none"
    "-device virtio-vga-gl"
    "-display sdl,gl=on"
  ];
  virtualisation.forwardPorts = [
    # Forward host port 2222 to guest port 22, for SSH access
    {
      from = "host";
      host.port = 2222;
      guest.port = 22;
    }
  ];

  # Enable limited DRM debugging
  # boot.kernelParams = ["drm.debug=0x1c"];
}
