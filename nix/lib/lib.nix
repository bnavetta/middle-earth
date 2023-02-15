{
  inputs,
  cell,
}: let
  inherit (inputs) nixpkgs colmena;
  lib = nixpkgs.lib // builtins;

  # Adapted from mkMicrovm - the the baseline `lib` doesn't have a `nixosSystem` function (I guess it's not instantiated enough?)
  nixosSystem = args: import "${nixpkgs.path}/nixos/lib/eval-config.nix" (args // {modules = args.modules;});
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
      extraModules = [
        # See https://github.com/zhaofengli/colmena/issues/60#issuecomment-1047199551
        # Putting this in extraModules means it won't interfere with colmena deployment while allowing reuse between colmena and nixos-rebuild
        colmena.nixosModules.deploymentOptions
      ];
    };
  in
    instantiatedSystem
    // {
      inherit meta;
    };
}
