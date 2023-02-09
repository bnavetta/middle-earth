# A std block for NixOS systems
{
  nixpkgs,
  sharedActions,
}: let
  lib = nixpkgs.lib // builtins;

  # Simplified from https://github.com/divnix/std/blob/97348aa1056414f1c97caa7e1a4c21efda3f24e5/src/mkCommand.nix
  # The mkCommand function turns a `command` string into a runnable shell script
  mkCommand = system: args:
    args
    // {
      command = nixpkgs.legacyPackages.${system}.writeShellScript "${args.name}" args.command;
    };

  nixosSystems = name: {
    inherit name;
    type = "nixosSystems";
    actions = {
      system,
      fragment,
      fragmentRelPath,
      target,
    }: let
      # TODO: look at https://github.com/zhaofengli/colmena instead of deploy-rs - built-in support for cross-deployment and local deployment
    in [
      (mkCommand system {
        name = "closure";
        description = "Build the system closure";
        command = ''
          echo ${target.config.system.build.toplevel}
        '';
      })
    ];
  };
in
  nixosSystems