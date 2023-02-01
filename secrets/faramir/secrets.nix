{identities}: let
  defaultRule = {publicKeys = identities.hosts.faramir ++ identities.admins;};
in {
  "root.age" = defaultRule;

  "zwave_js_ui.age" = defaultRule;
}
