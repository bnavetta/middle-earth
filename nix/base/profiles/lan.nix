# NixOS profile for devices on the local network
{lib, ...}: {
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

  # Prefer iwd over wpa_supplicant - generally considered more efficient, and it ties in pretty well with systemd-networkd
  networking.wireless.enable = lib.mkForce false;
  networking.wireless.iwd = {
    enable = true;

    settings = {
      Settings.AutoConnect = true;
      Network.EnableIPv6 = true;
    };
  };

  # Leverage agenix to configure iwd
  # https://github.com/NixOS/nixpkgs/pull/75800 discusses some of the caveats
  age.secrets.pastafi = {
    file = ../secrets/pastafi.age;
    path = "/var/lib/iwd/pastafi.psk";
  };
}
