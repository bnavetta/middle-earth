with builtins;
let
  keys = import ./lib/keys.nix;
  systems = import ./lib/systems.nix;

  # Admin users with access to all secrets
  admins = [ keys.users.ben.age ];

  # Build system-specific secrets
  mkSystemSecrets = system:
    let
      secretNames = if pathExists "${system.root}/secrets" then attrNames (readDir "${system.root}/secrets") else [ ];
      secrets = map
        (name: {
          # This can't be a store path, it has to be the relative path
          name = "systems/${system.name}/secrets/${name}";
          value = {
            publicKeys = admins ++ system.keys.all;
          };
        })
        secretNames;
    in
    listToAttrs secrets;

  systemSecrets = foldl' (a: b: a // b) { } (map mkSystemSecrets (attrValues systems));

  allSystemKeys = foldl' (acc: sys: acc ++ sys.all) [ ] (attrValues keys.systems);
in
systemSecrets // {
  "secrets/sysadmin_password.age".publicKeys = admins ++ allSystemKeys;
}
