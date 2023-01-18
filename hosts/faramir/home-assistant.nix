{ pkgs, config, ... }: {
  age.secrets.zwave_js_ui.file = ../../secrets/zwave_js_ui.age;

  # Ensure this directory exists so that HA can start. It may still require manual configuration (TODO: automate better)
  systemd.tmpfiles.rules = [
    "d /var/lib/home-assistant 0750 root root - -"
  ];

  # Expose Home Assistant locally for the iOS app (and ZWave JS for debugging)
  networking.firewall.allowedTCPPorts = [ 8123 8091 ];
  
  # Allow SSDP (the service discovery protocol used by UPnP, particularly for WeMo devices)
  # See https://discourse.nixos.org/t/ssdp-firewall-support/17809 and https://serverfault.com/a/911286/9166
  networking.firewall.extraPackages = [ pkgs.ipset ];
  networking.firewall.extraCommands = ''
    if ! ipset --quiet list upnp; then
      # Create a new ipset to store UPnP SSDP connections
      ipset create upnp hash:ip,port timeout 4
    fi
    # Match outgoing SSDP packets (sent to 239.255.250:1900 multicast address) and store the source IP address
    # and port into the upnp ipset
    # Unfortunately, this rule is recreated every time the firewall restarts (see https://github.com/NixOS/nixpkgs/issues/161328)
    iptables -A OUTPUT -d 239.255.255.250/32 -p udp -m udp --dport 1900 -j SET --add-set upnp src,src --exist
    # Match and accept incoming UDP packets sent to an address and port in the upnp ipset
    # These packets are responses to SSDP requests sent by UPnP clients on the host
    iptables -A nixos-fw -p udp -m set --match-set upnp dst,dst -j nixos-fw-accept
  '';

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
