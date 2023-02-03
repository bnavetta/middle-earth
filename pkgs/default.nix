# Entry point for locally-defined packages, structured as a Nixpkgs overlay
final: prev: {
  sources = prev.callPackage (import ./_sources/generated.nix) {};
  # Then call packages with final.callPackage
  apple-emoji = final.callPackage ./apple-emoji.nix {};

  bpb = prev.bpb.overrideAttrs (o: rec {
    inherit (final.sources.bpb) pname version src;
  });
}
