{
  inputs,
  cell,
}: let
  inherit (cell.lib) mkSimpleModule mkModule;
in {
  minimal = mkSimpleModule "Minimal set of base NixOS modules that also work on a VM" {
    imports = [
      cell.profiles.base
      cell.profiles.networking
      cell.profiles.state
      cell.profiles.systemUsers
    ];
  };

  default = mkSimpleModule "Default set of modules to apply to almost all NixOS systems" {
    imports = [
      cell.profiles.minimal
      cell.profiles.boot
    ];
  };
  base = mkModule "Common system configuration" (import ./profiles/base.nix {inherit inputs;});

  boot = mkModule "Bootloader configuration for EFI systems" (import ./profiles/boot.nix);
  state = mkModule "Mutable/immutable state management" (import ./profiles/state.nix {inherit inputs;});
  networking = mkModule "Baseline networking setup with systemd and Tailscale" (import ./profiles/networking.nix);
  systemUsers = mkModule "System user configuration" (import ./profiles/systemUsers.nix);

  lan = mkModule "Local network configuration" (import ./profiles/lan.nix);
  desktop = mkModule "Desktop environment" (import ./profiles/desktop {inherit inputs;});
  development = mkModule "Development environment" (import ./profiles/development);
}
