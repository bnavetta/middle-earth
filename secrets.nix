let
  keys = import ./lib/keys.nix;
in
{
  "secrets/sysadmin_password.age".publicKeys = [ keys.users.ben.age ] ++ builtins.attrValues keys.hosts;
  "secrets/zwave_js_ui.age".publicKeys = [ keys.users.ben.age keys.hosts.faramir ];
  "secrets/host/faramir/wireless.age".publicKeys = [ keys.users.ben.age keys.hosts.faramir ];
}
