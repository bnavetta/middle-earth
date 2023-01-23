with builtins;
let
  keys = import ./lib/keys.nix;
  systems = import ./lib/systems.nix;

  # Admin users with access to all secrets
  admins = [ keys.users.ben.age ];

  defaultSecrets = [ "pass.age" ];
  addDefaultSecrets = secrets: foldl' (acc: secret: if elem secret secrets then acc else acc ++ [ secret ]) secrets defaultSecrets;

  # Build system-specific secrets
  mkSystemSecrets = system:
    let
      # Ensure there's always a rule for pass.age, to aid in bootstrapping
      secretNames = if pathExists "${system.root}/secrets" then addDefaultSecrets (attrNames (readDir "${system.root}/secrets")) else defaultSecrets;
      secrets = map
        (name: {
          # This can't be a store path, it has to be the relative path
          name = "systems/${system.name}/secrets/${name}";
          value = {
            publicKeys = admins ++ system.keys.default;
          };
        })
        secretNames;
    in
    listToAttrs secrets;

  systemSecrets = foldl' (a: b: a // b) { } (map mkSystemSecrets (attrValues systems));

  allSystemKeys = foldl' (acc: sys: acc ++ sys.default) [ ] (attrValues keys.systems);
in
systemSecrets // {
  "secrets/sysadmin_password.age".publicKeys = admins ++ allSystemKeys;
}
