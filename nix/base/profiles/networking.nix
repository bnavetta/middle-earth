{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.middle-earth.networking;
in {
  options = {
  };

  config = {
    networking.useNetworkd = true;

    systemd.network = {
      enable = true;
      # For some reason, Tailscale is never considered online. Also, many of my machines have WiFi connections.
      wait-online.anyInterface = true;
    };

    services.resolved = {
      enable = true;
      fallbackDns = [
        "1.1.1.1#cloudflare-dns.com"
        "9.9.9.9#dns.quad9.net"
        "8.8.8.8#dns.google"
        "2606:4700:4700::1111#cloudflare-dns.com"
        "2620:fe::9#dns.quad9.net"
        "2001:4860:4860::8888#dns.google"
      ];
    };

    networking.firewall = {
      enable = true;

      # Needed for Tailscale
      checkReversePath = "loose";

      # Trust Tailnet traffic by default
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [config.services.tailscale.port];
    };

    # Always-enabled networking services
    services.tailscale.enable = true;
    services.openssh.enable = true;
  };
}
