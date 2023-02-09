{
  inputs,
  cell,
}: let
  # Wraps a function into a functor that includes a meta.description attribute for the std TUI
  mkDescribed = description: f: {
    meta = {inherit description;};
    # __functor is called with the attribute set first, but we don't need it
    __functor = _: f;
  };
in {
  inherit mkDescribed;

  # Create a described NixOS module
  mkModule = mkDescribed;

  # Create a described "simple" NixOS module, which produces configuration with no arguments
  mkSimpleModule = description: config: mkDescribed description (_inputs: config);
}
