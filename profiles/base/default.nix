# Profile for base NixOS settings applied to _all_ hosts
{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  imports = [./containers.nix ./users.nix ./networking.nix];

  age.identityPaths = [
    "/var/lib/age/identity.txt"
  ];

  time.timeZone = "America/New_York";

  environment = {
    # Core debugging and administration packages I basically always need
    # This also ensures they're available if home-manager and/or nix-shell aren't working
    systemPackages = with pkgs; [
      binutils
      coreutils
      curl
      dnsutils
      fd
      exa
      hwinfo
      git
      jq
      manix
      nmap
      lsof
      ripgrep
      vim
      btop
      htop
      atop
    ];
  };

  # Baseline settings
  boot.cleanTmpDir = true;
  # See https://haydenjames.io/linux-performance-almost-always-add-swap-part2-zram/
  # zram swap compresses first
  zramSwap.enable = true;

  # TODO: this is only useful on hosts with a display
  fonts.fonts = with pkgs; [apple-emoji];

  # Useful Nix settings
  # See https://nixos.wiki/wiki/Storage_optimization
  nix = {
    settings = {
      auto-optimise-store = true;
      # Sandbox when building to catch impure builds
      sandbox = true;

      # Give sudo-able users privileged access to Nix
      trusted-users = ["root" "@wheel"];
      allowed-users = ["@wheel"];
    };

    optimise.automatic = true;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # This keeps nix shells from getting garbage-collected
    extraOptions = ''
      #min-free = 536870912
      keep-outputs = true
      keep-derivations = true
      fallback = true
    '';
  };

  # To save space and time, don't generate documentation that I won't use,
  # like info pages and the NixOS manual (which I'd just read online)
  # Unlike documentation.enable = false, this keeps man pages
  documentation.dev.enable = false;
  documentation.doc.enable = false;
  documentation.info.enable = false;
  documentation.nixos.enable = false;

  # Userspace OOM killer that steps in earlier than the kernel, making it more effective
  # https://github.com/rfjakob/earlyoom
  services.earlyoom.enable = true;
}
