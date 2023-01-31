{
  localModules,
  flake-utils,
  flakes,
  ...
}: let
  system = flake-utils.lib.system.x86_64-linux;
in {
  stateVersion = "23.05";
  inherit system;

  extraModules = [
    ({...}: {
      middle-earth.services.wedding-website = {
        enable = true;
        enableACME = true;
        forceTLS = true;
      };
    })
    "${localModules}/digitalocean"
    ./nginx.nix
    flakes.wedding-website.nixosModules.${system}.wedding-website
  ];
}
