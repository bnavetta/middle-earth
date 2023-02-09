# TODO: see if it's possible to import from flakes in secrets.nix
# See https://github.com/ryantm/agenix/issues/86
builtins.fromJSON (builtins.readFile ./.secrets.nix.json)
