{
  pkgs,
  config,
  lib,
  ...
}: {
  # Container setup
  # This _should_ be a no-op if no containers are defined by other modules
  virtualisation.oci-containers.backend = "podman";

  environment.systemPackages = lib.mkIf (config.virtualisation.oci-containers.containers != {}) [pkgs.podman];
}
