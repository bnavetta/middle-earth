{
  inputs,
  cell,
}: let
  lib = nixpkgs.lib // builtins;

  inherit (inputs) nixpkgs colmena std;
  inherit (inputs.cells) secrets pippin;
in {
  default =
    (std.lib.dev.mkShell {
      name = "Middle Earth Devshell";
      nixago = [
        secrets.nixago.agenix
      ];

      packages = [
        nixpkgs.age-plugin-yubikey
      ];

      commands = [
        {
          package = nixpkgs.age;
          category = "Ops";
        }
        {
          package = colmena.packages.colmena;
          category = "Ops";
        }
        {
          name = "agepasswd";
          category = "Ops";
          help = "Generate a Linux password hash secret";
          command = ''
            if [[ $# -ne 1 ]]; then
              echo >&2 "Usage: agepasswd <path-to-secret>"
              exit 1
            fi
            ${lib.getExe nixpkgs.mkpasswd} -m yescrypt | agenix --editor - --edit "$1"
          '';
        }
        {
          package = nixpkgs.manix;
          category = "Nix";
        }
        {
          package = nixpkgs.nvfetcher;
          category = "Nix";
        }
        {
          name = "update-vscode";
          category = "Nix";
          help = "Update VSCode extension versions";
          command = ''
            cd ./nix/base/profiles/development/vscode &&
            ${lib.getExe nixpkgs.nvfetcher} -c sources.toml "$@"
          '';
        }
        {
          command = "nix fmt";
          name = "fmt";
          category = "Development";
        }
      ];

      imports = [
        # This adds the `std` CLI/TUI to the devshell
        std.std.devshellProfiles.default
        pippin.devshellProfiles.default
      ];
    })
    // {meta.description = "Middle Earth Devshell";};
}
