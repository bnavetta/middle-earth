{
  inputs,
  cell,
}: let
  inherit (inputs) nixpkgs nixos-generators;
  inherit (inputs.cells) base ben;
  lib = nixpkgs.lib // builtins;

  mkInstaller = sys: let
    localRoot = sys.config.middle-earth.state.localRoot;
    safeRoot = sys.config.middle-earth.state.safeRoot;
    installScript = nixpkgs.writeShellScriptBin "install-system" ''
      set -euo pipefail

      is_mounted() {
        mount | awk -v DIR="$1" '{ if ($3 == DIR) { exit 0 } } ENDFILE { exit -1 }'
      }

      die() {
        echo "$@" >&2
        exit 1
      }

      # TODO: partitioning
      # TODO: age identity

      if ! is_mounted "/mnt/${localRoot}"; then
        die "${localRoot} is not mounted under /mnt"
      fi

      if ! is_mounted "/mnt/${safeRoot}"; then
        die "${safeRoot} is not mounted under /mnt"
      fi

      echo "Generating machine ID..."
      systemd-machine-id-setup --root="/mnt/${localRoot}" --print

      echo "Installing system..."
      sudo nixos-install --system ${sys.config.system.build.toplevel} --no-root-password
      echo "Done!"
    '';
    modules = [
      ({
        pkgs,
        modulesPath,
        ...
      }: {
        imports = [
          base.profiles.base
          base.profiles.networking
          base.profiles.lan
          "${modulesPath}/profiles/installation-device.nix"
        ];

        system.stateVersion = "23.05";

        boot.loader.systemd-boot.enable = true;
        boot.kernelPackages = pkgs.linuxPackages_latest;

        users.users.root.openssh.authorizedKeys.keys = ben.lib.sshKeys;
        users.users.nixos.openssh.authorizedKeys.keys = ben.lib.sshKeys;

        environment.systemPackages = [
          installScript
        ];
      })
    ];
  in
    nixos-generators.nixosGenerate {
      format = "iso";
      system = sys.config.nixpkgs.system;
      inherit modules;
    };
in {
  inherit mkInstaller;
}
