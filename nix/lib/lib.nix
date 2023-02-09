{
  inputs,
  cell,
}: let
  lib = inputs.nixpkgs.lib // builtins;

  # Adapted from mkMicrovm - the the baseline `lib` doesn't have a `nixosSystem` function (I guess it's not instantiated enough?)
  nixosSystem = args: import "${inputs.nixpkgs.path}/nixos/lib/eval-config.nix" (args // { modules = args.modules; });
in {
  # mkSystem is a function used by `nixosSystem` cell blocks to build NixOS configurations.
  #
  # It's similar to the `std.lib.ops.mkMicrovm` function at https://github.com/divnix/std/blob/main/cells/lib/ops/mkMicrovm.nix
  # Instead of taking an attrset here, we could take a NixOS module and set nixpkgs configuration options from it,
  # like hive: https://github.com/divnix/hive/blob/main/pasteurize.nix (the `bee` options are used to set
  # up `nixpkgs` in an opinionated way, as applied by `pasteurize`). That requires some wierd partial evaluation to get nixpkgs.system though.
  mkSystem = {
    name, # TODO: is there a way to get this automatically, like fragmentRelPath in the block type?
    system,
    modules ? [],
    meta ? {},
  }: let
    autoModules = [
      {
        networking.hostName = name;
        nixpkgs = {
          config.allowUnfree = true;
        };
      }
    ];
    instantiatedSystem = nixosSystem {
      inherit system;
      modules = modules ++ autoModules;
    };
  in instantiatedSystem // {
    inherit meta;
  };
}