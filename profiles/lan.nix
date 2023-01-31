# NixOS profile for devices on the local network
{...}: {
  # Enable Avahi for mDNS
  services.avahi = {
    enable = true;
    nssmdns = true;
    ipv4 = true;
    ipv6 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # TODO: also set up WiFi
}
