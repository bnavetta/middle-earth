{inputs}: {
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  isMicroVM = options ? microvm;
  notMicroVM = !isMicroVM;
in {
  imports = [
    inputs.ragenix.nixosModules.age
    inputs.home-manager.nixosModules.home-manager
  ];

  #############################
  # Default Shell Environment #
  #############################

  environment = {
    # Core debugging and administration packages I basically always need
    # This also ensures they're available if home-manager and/or nix-shell aren't working
    systemPackages = with pkgs;
      [
        atop
        bat-extras.batman
        binutils
        btop
        coreutils
        curl
        dnsutils
        exa
        fd
        file
        fzf
        git
        hexyl
        htop
        hwinfo
        jq
        lsof
        manix
        nix-info
        nmap
        pciutils
        ripgrep
        rsync
        tmux
        vim
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
  
  ###################
  # Kernel and boot #
  ###################
  boot.kernelParams = [ "boot.shell_on_fail" ];

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

  nixpkgs.config.allowUnfree = true;

  nix = {
    nixPath = [
      # This enables nix-shell for testing out packages ad-hoc
      "nixpkgs=${inputs.nixpkgs.sourceInfo.outPath}"
      "home-manager=${inputs.home-manager}"
    ];

    settings = {
      extra-experimental-features = ["nix-command" "flakes"];

      # Keep in sync with nixConfig in flake.nix. The configuration there must be a literal expression, so we can't import from a shared location.
      substituters = [
        "https://cache.nixos.org"
        "https://nrdxp.cachix.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs-wayland.cachix.org"
        "https://microvm.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
        "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys="
      ];

      # See https://nixos.wiki/wiki/Storage_optimization
      auto-optimise-store = lib.mkIf notMicroVM true;
      # Sandbox when building to catch impure builds
      sandbox = true;

      # Give sudo-able users privileged access to Nix
      trusted-users = ["root" "@wheel"];
      allowed-users = ["@wheel"];
    };

    optimise.automatic = lib.mkIf notMicroVM true;

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
