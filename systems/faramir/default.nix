{ localModules, flake-utils, flakes, ... }: {
  stateVersion = "23.05";
  system = flake-utils.lib.system.aarch64-linux;

  extraModules = [
    ./wifi.nix
    ./home-assistant.nix
    flakes.nixos-hardware.nixosModules.raspberry-pi-4
    {
      # Enable GPU acceleration
      hardware.raspberry-pi."4".fkms-3d.enable = true;

      # Enable Avahi for mDNS
      services.avahi = {
        enable = true;
        nssmdns = true;
        ipv4 = true;
        ipv6 = true;
        publish = { enable = true; addresses = true; workstation = true; };
      };


      # Allow SSH on all interfaces, not just tailscale
      networking.firewall.allowedTCPPorts = [ 22 ];
    }
  ];
}
