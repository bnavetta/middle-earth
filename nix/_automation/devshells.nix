{
  inputs,
  cell,
}: let
  lib = nixpkgs.lib // builtins;

  inherit (inputs) nixpkgs std;
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
          package = nixpkgs.manix;
          category = "Nix";
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
