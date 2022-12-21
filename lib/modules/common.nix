# NixOS module for common settings
{ pkgs, config, ... }:
let
  keys = import ../keys.nix;
  lib = pkgs.lib;
in
{
  # Baseline settings
  boot.cleanTmpDir = true;
  # See https://haydenjames.io/linux-performance-almost-always-add-swap-part2-zram/
  # zram swap compresses first
  zramSwap.enable = true;

  networking.firewall = {
    enable = true;
    # Needed for Tailscale
    checkReversePath = "loose";

    # Always allow traffic from the Tailscale network
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  services.openssh.enable = true;
  # Only allow SSH via Tailscale (the Tailscale interface is trusted)
  services.openssh.openFirewall = false;
  services.tailscale.enable = true;

  age.secrets.sysadmin_password.file = ../../secrets/sysadmin_password.age;

  users.users =
    let
      sshKeys = [
        keys.users.ben.ssh
      ];
    in
    {
      root.openssh.authorizedKeys.keys = sshKeys;

      sysadmin = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        passwordFile = config.age.secrets.sysadmin_password.path;
        openssh.authorizedKeys.keys = sshKeys;
      };
    };

  programs.ssh.knownHosts = {
    # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
    gh1 = {
      hostNames = [ "github.com" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
    gh2 = {
      hostNames = [ "github.com" ];
      publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=";
    };
    gh3 = {
      hostNames = [ "github.com" ];
      publicKey = "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==";
    };
  };

  # See https://nixos.wiki/wiki/Storage_optimization
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Base home-manager settings
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  # Globally install some common tools for debugging in case things are _so_ broken that I can't get a nix-shell running :)
  environment.systemPackages = with pkgs; [ vim btop htop atop lsof ripgrep ];
}
