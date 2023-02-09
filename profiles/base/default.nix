# Profile for base NixOS settings applied to _all_ hosts
{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  imports = [./users.nix ./networking.nix];

  # TODO: this is only useful on hosts with a display
  fonts.fonts = with pkgs; [apple-emoji];
}
