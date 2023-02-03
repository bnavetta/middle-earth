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
in {
  imports = [
    # Enable devshell's git hook support
    "${extraModulesPath}/git/hooks.nix"
    ./git-hooks
  ];

  packages = with pkgs; [
    age
    age-plugin-yubikey
    alejandra
    cachix
    libguestfs-with-appliance
    mkpasswd
    nixos-generators
    shfmt
    treefmt
    nodePackages.prettier
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
    ++ lib.optionals (pkgs.stdenv.hostPlatform.isLinux && !pkgs.stdenv.buildPlatform.isDarwin) [
      # Linux-only commands
      (middleEarthCommand pkgs.nixos-generators)
      (middleEarthCommand inputs.deploy.packages.${pkgs.system}.deploy-rs)

      {
        category = "testvm";
        name = "testvm-run";
        help = "Run the `testvm` configuration in a QEMU VM";
        # command = ''
        #   nixos-generate --flake '.#testvm' \
        #     --format vm-bootloader --out-link testvm && \
        #   sudo testvm/bin/run-testvm-vm \
        #     -vga none \
        #     -device virtio-vga-gl \
        #     -display gtk,gl=on \
        #     -netdev bridge,id=tnet0,br=virbr0 -device virtio-net-pci,netdev=tnet0 $@'';
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
        name = "mknet";
        help = "Create a bridge network";
        command = ''
          sudo ip link add name virbr0 type bridge && \
            sudo ip link set dev enp5s0 master virbr0 && \
            sudo ip addr add 192.168.0.20/24 dev virbr0 && \
            sudo ip link set dev virbr0 up && \
            sudo iptables -I FORWARD -m physdev --physdev-is-bridged -j ACCEPT
        '';
      }
    ];
}
