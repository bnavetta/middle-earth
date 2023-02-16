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

      commands = [
        {
          package = colmena.packages.colmena;
          category = "Ops";
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
        secrets.devshellProfiles.default
      ];
    })
    // {meta.description = "Middle Earth Devshell";};
}
