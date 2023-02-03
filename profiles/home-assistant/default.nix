{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.middle-earth.services.home-assistant;
in {
  imports = [./ssdp.nix];

  options.middle-earth.services.home-assistant = {
    enable = lib.mkEnableOption "Home Assistant";

    zwave.device = lib.mkOption {
      type = lib.types.path;
      description = "Device path for the ZWave controller";
    };

    zwave.environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the environment file for ZWave-JS-UI";
    };

    stateDir =
      lib.mkOption
      {
        type = lib.types.path;
        description = "Directory for Home Assistant state and configuration";
        default = "/var/lib/home-assistant";
      };
  };

  config = lib.mkIf cfg.enable {
    # Ensure this directory exists so that HA can start. It may still require manual configuration (TODO: automate better)
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 root root - -"
    ];

    # Expose Home Assistant locally for the iOS app (and ZWave JS for debugging)
    networking.firewall.allowedTCPPorts = [8123 8091];

    virtualisation.oci-containers = {
      containers.homeassistant = {
        volumes = ["${cfg.stateDir}:/config"];
        environment.TZ = "America/New_York";
        image = "ghcr.io/home-assistant/home-assistant:2022.12.7";
        extraOptions = [
          "--network=host"
        ];
        dependsOn = ["zwave-js-ui"];
      };

      containers.zwave-js-ui = {
        volumes = ["zwave-js-ui:/usr/src/app/store"];
        environment = {
          TZ = "America/New_York";
          ZWAVEJS_EXTERNAL_CONFIG = "/usr/src/app/store/.config-db";
        };
        environmentFiles = [cfg.zwave.environmentFile];
        image = "zwavejs/zwave-js-ui:8.6.1";
        # Only allow localhost connections to the websocket
        ports = ["127.0.0.1:3000:3000" "8091:8091"];
        extraOptions = [
          "--device=${cfg.zwave.device}:/dev/zwave"
        ];
      };
    };
  };
}
