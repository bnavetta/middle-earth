{ config, ... }: {
  # Make sure there are DNS servers available - for some reason Faramir doesn't get them via DHCP reliably
  services.resolved = {
    enable = true;
    fallbackDns = [ "1.1.1.1#cloudflare-dns.com" "9.9.9.9#dns.quad9.net" "8.8.8.8#dns.google" "2606:4700:4700::1111#cloudflare-dns.com" "2620:fe::9#dns.quad9.net" "2001:4860:4860::8888#dns.google" ];
  };

  age.secrets.faramir_wireless.file = ./secrets/wireless.age;

  networking.wireless = {
    enable = true;
    environmentFile = config.age.secrets.faramir_wireless.path;
    networks.pastafi.psk = "@PASTAFI_PSK@";
    interfaces = [ "wlan0" ];
  };
}
