{
  inputs,
  cell,
}: let
  inherit (cell.lib) mkSimpleModule mkModule;
in {
  default = mkSimpleModule "Default set of modules to apply to almost all NixOS systems" {
    imports = [
      cell.profiles.base
      cell.profiles.boot
      cell.profiles.state
      cell.profiles.systemUsers
    ];
  };
  base = mkModule "Common system configuration" (import ./profiles/base.nix {inherit inputs;});

  boot = mkModule "Bootloader configuration for EFI systems" (import ./profiles/boot.nix);
  state = mkModule "Mutable/immutable state management" (import ./profiles/state.nix {inherit inputs;});
  systemUsers = mkModule "System user configuration" (import ./profiles/systemUsers.nix);
}
