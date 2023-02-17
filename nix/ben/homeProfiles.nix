{
  inputs,
  cell,
}: let
  inherit (inputs) nixpkgs;
  inherit (inputs.cells) base;

  lib = nixpkgs.lib // builtins // base.lib;

  # Move into `base` if this proves useful?
  # TODO: also posible to do something rake-leaves-like? (especially if it could auto-add docs and provide inputs+cell)
  module = desc: path: lib.mkModule desc (import path {inherit inputs cell;});
in {
  common = module "Common home configuration" ./homeProfiles/common.nix;
  desktop = module "NixOS desktop configuration" ./homeProfiles/desktop.nix;
  shell = module "Portable shell setup" ./homeProfiles/shell.nix;
}
