{...}: {
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  networking.firewall.allowedTCPPorts = [80 443];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "ben.navetta+acme@gmail.com";

  # Virtual host for Home Assistant on Faramir (TODO: separate from main nginx config)
  services.nginx.virtualHosts."home.bennavetta.com" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://faramir:8123";
      proxyWebsockets = true;
    };
  };
}
