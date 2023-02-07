{
  profiles,
  pkgs,
  inputs,
  self,
  ...
}: let
  testvm = self.nixosConfigurations.testvm;
  testvmSystem = testvm.config.system.build.toplevel;
  testvmPartition = testvm.config.system.build.disko;
  install-testvm = pkgs.writeShellScriptBin "install-testvm" ''
    set -euo pipefail

    echo "Partitioning disks..."
    sudo ${testvmPartition}

    echo "Installing system..."
    sudo nixos-install --system ${testvmSystem} --no-root-password

    echo "Done!"
  '';
in {
  imports = [
    profiles.nix-caches
  ];

  boot.loader.systemd-boot.enable = true;

  environment.systemPackages = [
    install-testvm
  ];

  # Required, but will be overridden in the resulting installer ISO.
  fileSystems."/" = {device = "/dev/disk/by-label/nixos";};

  # Could fork disko to add "existing-gpt" and "existing-partition" types which verify that a table/partition exists but won't format it? would have to make sure the deactivation logic doesn't zap anyways
  # _theoretically_, if you recreate an identical partition table then filesystems aren't lost (assuming windows isn't validating partition UUIDs)
  # so an "existing" partition type may be sufficient
  # or KISS - disko for NixOS-only, manual partitioning for dual boots (I probably want that assurance anyways?)
  # other TODOs:
  # - fix pool vs fs settings in disko config
  # - maybe switch from digga to flake.parts
  # - scripts to build per-system installer ISOs
  # - nixos-remote support for VMs, RPi
  # - nix-darwin setup
  # - can make installer _way_ simpler
  #     - if system is part of the ISO, don't need GitHub access at install time - app key can be a regular age secret for auto-upgrades
  #     - so installer flow is:
  #       1. Installer is run (either manually on a real machine or via nixos-remote)
  #       2. Installer connects to Tailscale (either QR code or auth key in cloud-config data)
  #       3. Installer partitions disk (if disko enabled)
  #       4. Installer generates age identity, copies it and Tailscale state into appropriate locations on /mnt
  #       5. <TODO: system won't activate correctly b/c it can't decrypt secrets - need to produce age identity ahead of time>
  #          host that generated the identity + secrets can provide it over SSH!
}
