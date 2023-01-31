# Profile that sets up Nix caches
# Every .nix file in this directory is imported as a Cachix configuration
# Based on https://github.com/divnix/digga/blob/main/examples/devos/profiles/cachix/default.nix
{
  pkgs,
  lib,
  ...
}: let
  cacheDir = ./.;
  # Convert a cache file name to an import path
  toImport = name: value: cacheDir + ("/" + name);
  # Filter directory entries to just cache modules
  isCache = name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix";
in {
  imports = lib.mapAttrsToList toImport (lib.filterAttrs isCache (builtins.readDir cacheDir));
  nix.settings.substituters = ["https://cache.nixos.org/"];
}
