{
  inputs,
  cell,
}: let
  inherit (inputs) nixpkgs;
  lib = nixpkgs.lib // builtins // cell.lib;
  module = desc: path: lib.mkModule desc (import path {inherit inputs cell;});
in {
  state = module "User-level state management" ./homeProfiles/state.nix;
}
