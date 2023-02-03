{
  suites,
  profiles,
  pkgs,
  lib,
  inputs,
  ...
}: {
  system.stateVersion = "23.05";

  imports = let
    hardwareModules = with inputs.nixos-hardware.nixosModules; [
      common-cpu-amd
      common-cpu-amd-pstate
      common-gpu-nvidia-nonprime
      common-pc-hdd
      common-pc-ssd
    ];
  in
    suites.desktop
    ++ [profiles.secureboot]
    ++ hardwareModules;

  # Must be set for ZFS
  networking.hostId = "c30a0615";

  # TODO: derive disks from partitioner config?
  middle-earth.state.impermanence = true;

  # Tailscale means installer and host can just call back and forth (HTTP, gRPC, etc.) - no need for magic wormhole
  # - installer sends over its public keys
  # - host adds them, sends over GitHub app key
  # for unattended cloud install, installer can fetch Tailscale auth key from DigitalOcean user data
  # installer can also grab networking info and send that back, to generate NixOS config (https://docs.digitalocean.com/reference/api/metadata-api)
}
