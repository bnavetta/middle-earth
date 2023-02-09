{inputs}: {
  config,
  lib,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;

  imports = [
    inputs.ragenix.nixosModules.age
    inputs.home-manager.nixosModules.home-manager
  ];

  middle-earth.state.persist.age = {
    mode = "0700";
    safe = true;
  };

  age.identityPaths = [
    "${config.middle-earth.state.persist.age.path}/identity.txt"
  ];

  #############################
  # Default Shell Environment #
  #############################

  environment = {
    # Core debugging and administration packages I basically always need
    # This also ensures they're available if home-manager and/or nix-shell aren't working
    systemPackages = with pkgs;
      [
        binutils
        coreutils
        curl
        dnsutils
        fd
        exa
        hwinfo
        git
        jq
        bat-extras.batman
        manix
        nix-info
        nmap
        lsof
        ripgrep
        vim
        btop
        htop
        atop
      ]
      ++ (lib.optionals (config.virtualisation.oci-containers.containers != {}) [pkgs.podman]);

    variables = {
      EDITOR = "vim";
    };

    shellAliases.man = "batman";
    shellAliases.ls = "exa --classify --color-scale --git -g --icons";

    # Add ~/bin and ~/.local/bin to $PATH
    homeBinInPath = true;
    localBinInPath = true;

    shells = with pkgs; [
      bashInteractive
      zsh
    ];
  };

  time.timeZone = "America/New_York";

  ######################
  # System cleanliness #
  ######################

  boot.cleanTmpDir = true;
  # See https://haydenjames.io/linux-performance-almost-always-add-swap-part2-zram/
  # zram swap compresses first
  zramSwap.enable = true;

  # Userspace OOM killer that steps in earlier than the kernel, making it more effective
  # https://github.com/rfjakob/earlyoom
  services.earlyoom.enable = true;

  ##############
  # Containers #
  ##############
  # This _should_ be a no-op if no containers are defined by other modules
  virtualisation.oci-containers.backend = "podman";

  ################
  # Nix settings #
  ################

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
      # keep-outputs = true
      # keep-derivations = true
      fallback = true
    '';
  };

  home-manager = {
    # This installs packages to /etc/profiles instead of $HOME/.nix-profile, which enables nixos-rebuild build-vm
    # It may become the default in the future.
    useUserPackages = true;

    # Use the system `pkgs` rather than a private Home Manager instance
    # This cuts down on work and ensures consistency
    useGlobalPkgs = true;
  };

  # To save space and time, don't generate documentation that I won't use,
  # like info pages and the NixOS manual (which I'd just read online)
  # Unlike documentation.enable = false, this keeps man pages
  documentation.man.enable = true;
  documentation.dev.enable = false;
  documentation.doc.enable = false;
  documentation.info.enable = false;
  documentation.nixos.enable = false;
}
