{...}: {
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
