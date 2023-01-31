{identities}: let
  defaultRule = {publicKeys = identities.hosts.elessar ++ identities.admins;};
in {
  "root.age" = defaultRule;
}
