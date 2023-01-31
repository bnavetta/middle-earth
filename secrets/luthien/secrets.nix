{identities}: let
  defaultRule = {publicKeys = identities.hosts.luthien ++ identities.admins;};
in {
  "root.age" = defaultRule;
}
