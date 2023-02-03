# Common networking setup using the systemd stack and Tailscale
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.middle-earth.networking;
in {
  options = {
    middle-earth.networking = {
      expectedInterfaces = mkOption {
        type = types.listOf types.str;
        description = ''
          Expected network interfaces that systemd-networkd-wait-online will wait
          on before reporting that the network is online.
        '';
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.expectedInterfaces != [];
        message = "middle-earth.networking.expectedInterfaces cannot be empty. Otherwise startup will hang waiting on Tailscale.";
      }
    ];

    networking.useNetworkd = true;

    systemd.network = {
      enable = true;
    };

    systemd.network.wait-online.extraArgs = map (i: "--interface=${i}") cfg.expectedInterfaces;

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

    services.tailscale.enable = true;

    # Enable SSH, but only via Tailscale (since the interface is trusted)
    services.openssh = {
      enable = true;
      openFirewall = false;
    };
  };
}
