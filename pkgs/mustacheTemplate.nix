/*
* Function to render a Mustache template using Nix configuration data
* Approach from https://pablo.tools/blog/computers/nix-mustache-templates/
*
* This is added as a package because it needs pkgs, but conceptually it ought to be a library...
*/
{pkgs, ...}: name: template: data:
pkgs.stdenv.mkDerivation {
  inherit name;

  nativeBuildInputs = [pkgs.mustache-go];

  passAsFile = ["jsonData"];
  jsonData = builtins.toJSON data;

  # Disable phases which are not needed. In particular the unpackPhase will
  # fail, if no src attribute is set
  phases = ["buildPhase" "installPhase"];

  buildPhase = ''
    ${pkgs.mustache-go}/bin/mustache $jsonDataPath ${template} > rendered
  '';

  installPhase = ''
    cp rendered $out
  '';
}
