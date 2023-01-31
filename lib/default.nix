{lib}:
lib.makeExtensible (self: let
  callLibs = file: import file {lib = self;};
in rec {
  # Define additional library functions here. This uses digga.lib.makeExtensible to stack on top of digga.lib and nixpkgs.lib
  # For grouping, create files that take { lib } and import them like so:
  # foo = callLibs ./foo.nix;
  # In configs, these libraries, along with digga.lib and nixpkgs.lib, are available under `lib`
})
