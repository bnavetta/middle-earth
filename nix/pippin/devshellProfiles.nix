{
  inputs,
  cell,
}: let
  inherit (inputs) nixpkgs;
  inherit (inputs.std) std;

  lib = nixpkgs.lib // builtins;

  nixGLWrapper = nixpkgs.writeShellScript "nixGL" ''
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
  default = {...}: {
    commands = [
      {
        name = "pippin-run";
        command = "${nixGLWrapper} ${lib.getExe std.cli.default} //pippin/vms/pippin:run";
        category = "Development";
        help = "Run Pippin in a microVM";
      }
    ];
  };
}
