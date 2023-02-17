{
  inputs,
  cell,
}: let
  inherit (inputs) nixpkgs nixos-generators;
  inherit (inputs.cells) base ben;
  lib = nixpkgs.lib // builtins;

  # Builds a derivation for an installer ISO
  mkInstaller = sys: let
    localRoot = sys.config.middle-earth.state.localRoot;
    safeRoot = sys.config.middle-earth.state.safeRoot;
    hostName = sys.config.networking.hostName;
    ageRootIdentity = ../ben/age-identities.txt;
    ageIdentitySrc = ../${hostName}/secrets/identity.age;
    ageIdentityDest = lib.head sys.config.age.identityPaths;
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

      if ! is_mounted "/mnt/${localRoot}"; then
        die "${localRoot} is not mounted under /mnt"
      fi

      if ! is_mounted "/mnt/${safeRoot}"; then
        die "${safeRoot} is not mounted under /mnt"
      fi

      echo "Generating machine ID..."
      systemd-machine-id-setup --root="/mnt/${localRoot}" --print

      echo "Installing age identity..."
      mkdir -p "$(dirname "/mnt/${ageIdentityDest}")"
      age --decrypt -i "${ageRootIdentity}" -o "/mnt/${ageIdentityDest}" "${ageIdentitySrc}"

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
          # nixos-generators' install-iso format already adds the installation-cd-base.nix module,
          # so this isn't entirely necessary
          # (https://github.com/nix-community/nixos-generators/blob/1e0a05219f2a557d4622bc38f542abb360518795/formats/install-iso.nix)
          # However, the minimal profile sets a few extra options for cache-friendliness (at the cost
          # of making the installer a little larger)
          # (https://github.com/NixOS/nixpkgs/blob/a64c98dcfa0881b86268a74001e74fa27f3cb65c/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix)
          "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
        ];

        system.stateVersion = "23.05";

        boot.kernelPackages = pkgs.linuxPackages_latest;
        boot.supportedFilesystems = ["zfs"];

        networking.hostId = "4a7cf688";

        users.users.root.openssh.authorizedKeys.keys = ben.lib.sshKeys;
        users.users.nixos.openssh.authorizedKeys.keys = ben.lib.sshKeys;

        environment.systemPackages = [
          installScript
          pkgs.age
          pkgs.age-plugin-yubikey
        ];
      })
    ];
  in
    nixos-generators.nixosGenerate {
      format = "install-iso";
      system = sys.config.nixpkgs.system;
      inherit modules;
    };

  # Builds a script that flashes an installer ISO to a USB drive
  mkFlash = name: image: let
    pv = lib.getExe nixpkgs.pv;
    fzf = lib.getExe nixpkgs.fzf;
  in
    nixpkgs.writeShellScriptBin name ''
      set -euo pipefail

      # From https://aldoborrero.com/posts/2023/01/15/setting-up-my-machines-nix-style/
      iso="$(find "${image}/iso" -name '*.iso')"

      if [[ $# -gt 0 ]]; then
        dev="$1"
      else
        dev="/dev/$(lsblk -l -n --output RM,NAME,FSTYPE,SIZE,LABEL,TYPE,VENDOR,UUID | awk '{ if ($1 == 1) { print } }' | ${fzf} --height='~20%' | awk '{print $2}')"
      fi

      echo "Image:"
      ls -lh "$iso"
      read -p "Flash to $dev? " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${pv} -tpreb "$iso" | sudo dd bs=4M of="$dev" iflag=fullblock conv=notrunc,noerror oflag=sync
        sudo sync
      fi

      echo "Done!"
      sudo fdisk -l "$dev"

      read -p "Verify hashes? " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        expected="$(shasum -a 256 "$iso" | awk '{ print $1 }')"
        echo "ISO image hash: $expected"
        actual="$(sudo shasum -a 256 "$dev" | awk '{ print $1 }')"
        echo "Device hash: $actual"
        if [[ "$expected" != "$actual" ]]; then
          echo >&2 "Hashes are different!"
          exit 1
        fi
      fi
    '';
in {
  inherit mkInstaller mkFlash;
}
