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
      hostName = lib.baseNameOf fragmentRelPath;
      # Check if colmena is set up for local or remote deployment
      inherit (target.config.deployment) allowLocalDeployment targetHost;
    in
      [
        (mkCommand system {
          name = "closure";
          description = "Build the system closure";
          command = ''
            echo ${target.config.system.build.toplevel}
          '';
        })
      ]
      ++ (lib.optionals allowLocalDeployment [
        (mkCommand system {
          name = "apply-local";
          description = "Apply the system configuration locally";
          command = ''
            colmena apply-local --sudo "$@"
          '';
        })
      ])
      ++ (lib.optionals (targetHost != null) [
        (mkCommand system {
          name = "apply";
          description = "Apply the system configuration remotely";
          command = ''
            colmena apply --on ${hostName} "$@"
          '';
        })
      ]);
  };
in
  nixosSystems
