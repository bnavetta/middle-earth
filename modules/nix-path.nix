{
  channel,
  inputs,
  ...
}: {
  # Add useful entries to nix-path
  nix.nixPath = [
    "nixpkgs=${channel.input}"
    "home-manager=${inputs.home-manager}"
  ];
}
