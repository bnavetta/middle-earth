{
  suites,
  profiles,
  pkgs,
  lib,
  modulesPath,
  inputs,
  ...
}: {
  system.stateVersion = "23.05";

  imports =
    suites.desktop
    ++ [
      inputs.disko.nixosModules.disko
    ];

  # Must be set for ZFS
  networking.hostId = "c30a0615";

  disko.devices = import ./disko-config.nix {};
  disko.enableConfig = true;

  middle-earth.state.impermanence = true;

  middle-earth.networking.expectedInterfaces = [
    "eth0"
  ];

  boot.kernelModules = ["virtio_gpu" "virtio_vga"];
  hardware.opengl.extraPackages = [pkgs.virglrenderer];

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Known bugs:
  # - The cursor will be wonky in sway: https://github.com/swaywm/sway/issues/6581
  # - the virtualisation options only exist when run via generator, and so have to be commented out when debugging with `nix eval`

  # Ensure this uses QEMU built with OpenGL support
  /*
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
  */

  # Enable limited DRM debugging
  # boot.kernelParams = ["drm.debug=0x1c"];
}
