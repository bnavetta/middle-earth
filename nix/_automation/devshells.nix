{
  inputs,
  cell,
}: let
  lib = nixpkgs.lib // builtins;

  inherit (inputs) nixpkgs std;
  inherit (inputs.cells) secrets;
in
  lib.mapAttrs (_: std.lib.dev.mkShell) {
    default = { ... }: {
      name = "Middle Earth Devshell";
      nixago = [
        secrets.nixago.sops
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
          package = nixpkgs.manix;
          category = "Nix";
        }
      ];

      imports = [
        # This adds the `std` CLI/TUI to the devshell
        std.std.devshellProfiles.default
      ];
    };
  }