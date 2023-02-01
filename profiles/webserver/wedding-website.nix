{ inputs
, ...
}: {
  imports = [ inputs.wedding-website.nixosModules.x86_64-linux.wedding-website ];

  middle-earth.services.wedding-website = {
    enable = true;
    enableACME = true;
    forceTLS = true;
  };
}
