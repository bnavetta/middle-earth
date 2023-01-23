# Library exporting all system configurations
with builtins;
let
  mkSystem = name: typ:
    assert typ == "directory";
    let dir = ../systems/${name}; in
    {
      inherit name;
      root = dir;
      keys =
        let
          ssh = map (keyName: readFile "${dir}/host_ssh_keys/${keyName}") (attrNames (readDir "${dir}/host_ssh_keys"));
          age = if pathExists "${dir}/age-identity.txt" then [ (readFile "${dir}/age-identity.txt") ] else [ ];
        in
        {
          inherit ssh; inherit age; default = if age == [ ] then ssh else age;
        };
      loadConfig = args: import "${dir}" args;
    };
in
mapAttrs mkSystem (readDir ../systems)
