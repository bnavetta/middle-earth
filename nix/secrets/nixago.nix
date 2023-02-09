{
  inputs,
  cell,
}: let
  inherit (inputs) nixpkgs agenix-cli;
  lib = nixpkgs.lib // builtins;

  schemaModule = let
    inherit (lib) mkOption types;
    strings = types.listOf types.str;
  in {
    options = {
      identities = mkOption {
        type = types.attrsOf types.str;
        description = "Named age recipients";
      };

      groups = mkOption {
        type = types.attrsOf strings;
        description = "Named groups of identitities";
      };

      paths = mkOption {
        type = types.listOf (types.submodule {
          options = {
            glob = mkOption {
              type = types.str;
              description = "Glob of files that this rule applies to";
            };

            identities = mkOption {
              type = strings;
              description = "Identities to encrypt the secret with";
            };

            groups = mkOption {
              type = strings;
              description = "Groups of identities to encrypt the secret with";
            };
          };
        });
      };
    };
  };

  # Find all `secrets` cell blocks
  configs = let
    # Filter out the system-specific entries in inputs.cells
    # From https://github.com/divnix/std/blob/ec62c8acb468708902735dc037225e46a49f8bdc/cells/std/nixago/conform.nix#L25
    cellNames = lib.subtractLists lib.systems.doubles.all (lib.attrNames inputs.cells);
    cells = lib.map (c: inputs.cells.${c}) cellNames;
  in
    lib.catAttrs "secrets" cells;
  evaluated = lib.evalModules {
    modules = [schemaModule] ++ configs;
  };
in {
  agenix = inputs.std.lib.dev.mkNixago {
    configData = evaluated.config;
    output = ".agenix.toml";
    format = "toml";
    commands = [
      {
        package = agenix-cli.packages.agenix-cli;
        name = "agenix";
        help = "age-encrypted secrets for NixOS";
        category = "Ops";
      }
    ];
  };
}
