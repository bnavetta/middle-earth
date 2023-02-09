{
  inputs,
  cell,
}: let
  inherit (inputs) nixpkgs ragenix;
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

      secrets = mkOption {
        type = types.listOf (types.submodule {
          options = {
            path = mkOption {
              type = types.path;
              description = "Path to the secret file";
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

  # Substitution helpers
  subst = defns: name: if lib.hasAttr name defns then defns.${name} else name;

  # Find all real cells, filtering out the system-specific entries
  # From https://github.com/divnix/std/blob/ec62c8acb468708902735dc037225e46a49f8bdc/cells/std/nixago/conform.nix#L25
  cellNames = lib.subtractLists lib.systems.doubles.all (lib.attrNames inputs.cells);

  # Find all `secrets` cell blocks
  configs = lib.catAttrs "secrets" (lib.map (c: inputs.cells.${c}) cellNames);

  identities = lib.foldl (acc: i: acc // i) {} (lib.catAttrs "identities" configs);
  groups = let
    # First, combine the group declarations across all cells
    unresolved = lib.zipAttrsWith (_: values: lib.flatten values) (lib.catAttrs "groups" configs);
    # Then, resolve identities
    resolved = lib.mapAttrs (_: members: lib.map (subst identities) members) unresolved;
  in resolved;

  # Now, construct rules from each cell
  # This logic to figure out the relative path is kind of bleh
  rules = let
    mkRule = cell: rule: let
      path = "nix/${cell}/${rule.path}";
      directIdentities = if rule ? identities then lib.map (subst identities) rule.identities else [];
      groupIdentities = if rule ? groups then lib.concatMap (subst groups) rule.groups else [];
    in { name = path; value = { publicKeys = directIdentities ++ groupIdentities; }; };
    mkCellRules = cell: lib.map (mkRule cell) (lib.attrByPath ["secrets" "secrets"] [] inputs.cells.${cell});
  in lib.listToAttrs (lib.concatMap mkCellRules cellNames);

  evaluated = lib.evalModules {
    modules = [schemaModule] ++ configs;
  };
in {
  agenix = inputs.std.lib.dev.mkNixago {
    configData = rules;
    output = ".secrets.nix.json";
    format = "json";
    commands = [
      {
        package = ragenix.packages.ragenix;
        name = "agenix";
        help = "age-encrypted secrets for NixOS";
        category = "Ops";
      }
    ];
  };
}
