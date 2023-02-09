# Flake module for setting up development shell tools and scripts
{self, ...}: {
  perSystem = {
    self',
    inputs',
    pkgs,
    config,
    ...
  }: let
    ragenix = inputs'.ragenix.packages.ragenix;

    shell = pkgs.mkShell {
      packages = with pkgs; [
        age
        age-plugin-yubikey
        manix

        self'.packages.ragenix-wrapped
        inputs'.std.packages.default
      ];
    };
  in {
    packages.glWrapper = pkgs.writeShellScript "glWrapper" ''
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

    packages.ragenix-wrapped = pkgs.writeShellScriptBin "agenix" ''
      exec ${ragenix}/bin/agenix \
            --rules ./secrets/secrets.nix \
            --identity="./users/users/$USER/age-identities.txt" \
            "$@"
    '';

    mission-control.scripts = {
      agenix = {
        category = "Secrets";
        description = "age-encrypted secrets for NixOS";
        exec = self'.packages.ragenix-wrapped;
      };

      agepasswd = {
        category = "Secrets";
        description = "Generate Linux password hash secret";
        exec = ''
          if [[ $# -ne 1 ]]; then
            echo >&2 "Usage: , agepasswd <path-to-secret>"
            exit 1
          fi
          ${pkgs.mkpasswd}/bin/mkpasswd -m yescrypt | ${self'.packages.ragenix-wrapped}/bin/agenix --editor - --edit "$1"
        '';
      };

      fmt = {
        description = "Format source files";
        exec = "nix fmt";
        category = "Tools";
      };
    };

    devShells.default = config.mission-control.installToDevShell shell;
  };
}
