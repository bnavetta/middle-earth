{ suites
, profiles
, config
, pkgs
, lib
, inputs
, ...
}: {
  system.stateVersion = "23.05";

  imports =
    suites.pi
    ++ [
      inputs.nixos-hardware.nixosModules.raspberry-pi-4
      ./hardware-configuration.nix
    ];

  # Enable GPU acceleration
  hardware.raspberry-pi."4".fkms-3d.enable = true;

  age.secrets.zwave_js_ui.file = ../../secrets/faramir/zwave_js_ui.age;

  middle-earth.services.home-assistant = {
    enable = true;
    zwave.device = "/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_8247a4ec0945eb118185aa52b003b68c-if00-port0";
    zwave.environmentFile = config.age.secrets.zwave_js_ui.path;
  };
}
