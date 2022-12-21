{ pkgs, config, ... }: {
  age.secrets.zwave_js_ui.file = ../../secrets/zwave_js_ui.age;

  # Ensure this directory exists so that HA can start. It may still require manual configuration (TODO: automate better)
  systemd.tmpfiles.rules = [
    "d /var/lib/home-assistant 0750 root root - -"
  ];

  # Expose Home Assistant locally for the iOS app (and ZWave JS for debugging)
  networking.firewall.allowedTCPPorts = [ 8123 8091 ];

  virtualisation.oci-containers = {
    containers.homeassistant = {
      volumes = [ "/var/lib/home-assistant:/config" ];
      environment.TZ = "America/New_York";
      image = "ghcr.io/home-assistant/home-assistant:2022.12.7";
      extraOptions = [
        "--network=host"
      ];
      dependsOn = [ "zwave-js-ui" ];
    };

    containers.zwave-js-ui = {
      volumes = [ "zwave-js-ui:/usr/src/app/store" ];
      environment = {
        TZ = "America/New_York";
        ZWAVEJS_EXTERNAL_CONFIG = "/usr/src/app/store/.config-db";
      };
      environmentFiles = [ config.age.secrets.zwave_js_ui.path ];
      image = "zwavejs/zwave-js-ui:8.6.1";
      # Only allow localhost connections to the websocket
      ports = [ "127.0.0.1:3000:3000" "8091:8091" ];
      extraOptions = [
        "--device=/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_8247a4ec0945eb118185aa52b003b68c-if00-port0:/dev/zwave"
      ];
    };
  };
}
