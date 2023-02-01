with builtins; let
  identities = import ../lib/identities.nix;

  scope = prefix: attrs:
    listToAttrs (map
      (name: {
        name = prefix + name;
        value = attrs.${name};
      })
      (attrNames attrs));
  include = path: scope (path + "/") (import ./${path}/secrets.nix {inherit identities;});

  allSecrets = [
    (include "elessar")
    (include "faramir")
    (include "luthien")
    (with identities; {
      "sysadmin_password.age".publicKeys = admins ++ allHosts;

      "pastafi.age".publicKeys = admins ++ hosts.faramir ++ hosts.elessar;
    })
  ];
in
  foldl' (x: y: x // y) {} allSecrets
