{
  self,
  inputs,
  pkgs,
  lib,
  extraModulesPath,
  ...
}: let
  # devshell groups commands into categories
  commandIn = category: package: {inherit package category;};
  middleEarthCommand = commandIn "middle-earth";

  glWrapper = pkgs.writeShellScript "glWrapper" ''
    source /etc/os-release
    if [[ "$ID" == "nixos" ]]; then
      exec "$@"
    else
      # nixGL is impure (when using NVIDIA) because it needs to detect the driver version
      # So, instead of installing it in the devshell, use nix run
      echo "Wrapping non-NixOS OpenGL..."
      exec nix run --impure github:guibou/nixGL -- "$@"
    fi
  '';

  installerLink = "installer";
  vmName = "middle-earth-testvm";

  buildInstaller = pkgs.writeShellScript "createInstaller" ''
    nixos-generate --flake '.#installer' --format install-iso --out-link ${installerLink}
  '';

  createVM = pkgs.writeShellScript "createVM" ''
    installer_iso="$(find -L ${installerLink} -name '*.iso')"
    echo "Using: $(which virt-install)"

    virt-install --name ${vmName} \
      --memory=8192 \
      --vcpus=4 \
      --disk "$HOME/big/${vmName}.qcow2,device=disk,bus=virtio,size=32" \
      --cdrom "$installer_iso" \
      --boot "loader=${pkgs.OVMF.firmware},nvram.template=${pkgs.OVMF.variables},loader.readonly=yes,loader.type=pflash,loader_secure=no" \
      --osinfo nixos-unstable \
      --graphics type=sdl,gl.enable=yes \
      --video model.type=virtio,model.acceleration.accel3d=yes \
  '';

  onLinux = pkgs.stdenv.hostPlatform.isLinux && !pkgs.stdenv.buildPlatform.isDarwin;
in {
  imports = [
    # Enable devshell's git hook support
    "${extraModulesPath}/git/hooks.nix"
    ./git-hooks
  ];

  packages = with pkgs;
    [
      age
      age-plugin-yubikey
      alejandra
      cachix
      mkpasswd
      shfmt
      treefmt
      # virt-manager
      nodePackages.prettier
    ]
    ++ lib.optionals onLinux [
      nixos-generators
      libguestfs-with-appliance
    ];

  commands =
    [
      {
        category = "middle-earth";
        name = "agenix";
        help = "age-encrypted secrets for NixOS";
        command = "cd $PRJ_ROOT; ${pkgs.ragenix}/bin/agenix --rules=./secrets/secrets.nix --identity=./users/users/$USER/age-identities.txt $@";
      }
      {
        category = "middle-earth";
        name = "agepasswd";
        help = "Generate an age-encrypted password hash";
        command = "mkpasswd -m yescrypt | agenix --editor - --edit $@";
      }
      (middleEarthCommand pkgs.cachix)
      {
        category = "middle-earth";
        name = pkgs.nvfetcher.pname;
        help = pkgs.nvfetcher.meta.description;
        command = "cd $PRJ_ROOT/pkgs; ${pkgs.nvfetcher}/bin/nvfetcher -c ./sources.toml $@";
      }

      (commandIn "formatter" pkgs.treefmt)
    ]
    ++ lib.optionals onLinux [
      # Linux-only commands
      (middleEarthCommand pkgs.nixos-generators)
      (middleEarthCommand inputs.deploy.packages.${pkgs.system}.deploy-rs)

      {
        category = "middle-earth";
        name = "build-installer";
        help = "Build the installer ISO";
        command = "${buildInstaller}";
      }

      {
        category = "testvm";
        name = "testvm-create";
        help = "Create a new test VM";
        command = "${createVM}";
      }

      {
        category = "testvm";
        name = "testvm-destroy";
        help = "Destroy the test VM";
        command = "virsh destroy ${vmName}; virsh undefine ${vmName} --nvram; rm -f $HOME/big/${vmName}.qcow2";
      }

      {
        category = "testvm";
        name = "testvm-run";
        help = "Run the `testvm` configuration in a QEMU VM";
        command = ''
          ${glWrapper} nixos-generate --flake '.#testvm' --format vm-bootloader --run
        '';
      }

      {
        category = "testvm";
        name = "testvm-mount";
        help = "Mount the testvm filesystem";
        command = "mkdir -p mnt && guestmount -a testvm.qcow2 -m /dev/sda --ro mnt";
      }

      {
        category = "testvm";
        name = "testvm-unmount";
        help = "Mount the testvm filesystem";
        command = "guestunmount mnt";
      }

      {
        category = "testvm";
        name = "testvm-ssh";
        help = "SSH into the testvm";
        command = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 2222 sysadmin@localhost $@";
      }
    ];
}
