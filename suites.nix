{profiles}:
with profiles; rec {
  base = [profiles.base profiles.nix-caches];

  server = base ++ [profiles.droplet profiles.webserver];
  desktop = base ++ [profiles.lan profiles.secureboot];
  pi = base ++ [profiles.lan profiles.home-assistant];
}
