# Flake module that produces a Colmena configuration for each nixosConfiguration
# This is based on https://github.com/zhaofengli/colmena/issues/60
# Alternatively, this _could_ probably be handled via std
{
  self,
  inputs,
  ...
}: let
  lib = inputs.nixpkgs.lib // builtins;
  # Convert a nixosSystem config to a Colmena host
  mkColmenaHost = name: sys: {
    nixpkgs.system = sys.config.nixpkgs.system;
    imports = sys._module.args.modules;
  };
  hosts = lib.mapAttrs mkColmenaHost self.nixosConfigurations;
in {
  flake = {
    colmena =
      {
        meta = {
          description = "Middle Earth - my personal machines";
          # Unfortunately, colmena requires an instantiated nixpkgs, so we have to set a system here
          # And perSystem doesn't produce the right output structure
          nixpkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
          };
        };
      }
      // hosts;
  };
}
