{
  inputs,
  cell,
}: let
  inherit (inputs) nixpkgs;
  inherit (inputs.cells) base;

  lib = nixpkgs.lib // builtins // base.lib;

  # Move into `base` if this proves useful?
  module = desc: path: lib.mkModule desc (import path {inherit inputs cell;});
in {
  common = module "Common home configuration" ./homeProfiles/common.nix;
  desktop = module "NixOS desktop configuration" ./homeProfiles/desktop.nix;
}
