{
  inputs,
  cell
}: let
  inherit (inputs) nixpkgs;
  lib = nixpkgs.lib // builtins;
  inherit (lib) or;

  rule = with inputs.yants; struct "rule" {
    pathRegex = string;
    users = option (list string);
    hosts = option (list string);
  };

  # Extract keys from user and host cells
  userKeys = lib.mapAttrs (name: cell: lib.attrByPath ["sops" "user" "keys"] [] cell) inputs.cells;
  hostKeys = lib.mapAttrs (name: cell: lib.attrByPath ["sops" "host" "keys"] [] cell) inputs.cells;

  # Convert a rule definition into a SOPS creation rule
  mkRule = cell: r:
    let
      validated = rule r;
    # Select keys by name, with a special `*` shorthand to match all
    getKeys = attr: defined:
      let
        selected = if lib.hasAttr attr validated then validated.${attr} else [];
        all = lib.flatten (lib.attrValues defined);
      in lib.concatMap (name: if name == "*" then all else defined.${name}) selected;
  in {
    path_regex = "nix/${cell}/" + validated.pathRegex;
    key_groups = [ { age = lib.unique ((getKeys "users" userKeys) ++ (getKeys "hosts" hostKeys)); } ];
  };

  rulesByCell = lib.mapAttrs (name: cell: lib.map (mkRule name) (lib.attrByPath ["sops" "rules"] [] cell)) inputs.cells;
  allRules = lib.flatten (lib.attrValues rulesByCell);
in {
  sops = inputs.std.lib.dev.mkNixago {
    configData = {
      creation_rules = allRules;
    };
    output = ".sops.yaml";
    format = "yaml";
    packages = [nixpkgs.sops];
  };

  # Next steps:
  # 2. create some sops secrets
  # 3. test deploying them
}