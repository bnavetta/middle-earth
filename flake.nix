{
  description = "Ben's infrastructure, Nix edition";

  # nix.conf options set while evaluating this flake
  nixConfig = {
    extra-experimental-features = "nix-command flakes";
    # Keep in sync with nix/base/profiles/base.nix. The configuration here must be a literal expression, so we can't import from a shared location.
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nrdxp.cachix.org"
      "https://nix-community.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://microvm.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys="
    ];
  };

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    # Packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nur.url = "github:nix-community/NUR";

    # Flake management
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-root.url = github:srid/flake-root;
    mission-control.url = github:Platonic-Systems/mission-control;
    yants.url = "github:divnix/yants";
    std = {
      url = "github:divnix/std";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.yants.follows = "yants";
      inputs.microvm.url = "github:astro/microvm.nix";
      inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixago.follows = "nixago";
    };
    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # system utilities

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixago = {
      url = "github:nix-community/nixago";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # my flakes

    wedding-website = {
      url = "git+ssh://git@github.com/bnavetta/follettnavetta.wedding.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO: also add LnL7/nix-darwin if applicable
  };

  outputs = {
    self,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      flake = {
        overlays = {
          ragenix = inputs.agenix.overlays.default;
        };
      };

      std.grow = {
        cellsFrom = ./nix;
        cellBlocks = with inputs.std.blockTypes; let
          nixosSystems = import ./tools/nixosSystems.nix {
            inherit (inputs.std) sharedActions;
            inherit (inputs) nixpkgs;
          };
        in [
          # Used to factor out agenix configuration
          ((data "secrets") // {cli = false;})
          # Library functions
          (functions "lib")
          # NixOS / Home Manager profiles
          (functions "profiles")
          (functions "homeProfiles")
          # NixOS system configurations and VMs
          (nixosSystems "nixos")
          (microvms "vms")
          (runnables "ops")
          # Nixago templates
          (nixago "nixago")
          # Developer shells
          (devshells "devshells")
          (functions "devshellProfiles")
        ];

        nixpkgsConfig = {allowUnfree = true;};
      };

      std.pick = {
        nixosConfigurations = [
          ["elessar" "nixos"]
        ];
      };

      imports = [
        inputs.std.flakeModule
        inputs.flake-root.flakeModule
        inputs.mission-control.flakeModule
        inputs.treefmt.flakeModule
        inputs.pre-commit-hooks-nix.flakeModule
        ./tools/colmena.nix
      ];

      # systems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux"];
      # Linux only to unblock install
      systems = [ "x86_64-linux" ];

      perSystem = {
        config,
        pkgs,
        system,
        ...
      }: let
        # Shared settings for treefmt and pre-commit (this works as long as both use the same names for formatters)
        formatters = {
          alejandra.enable = true;
          prettier.enable = true;
          shellcheck.enable = false;
          shfmt.enable = true;
        };
      in {
        # use std with a custom block type for NixOS configurations
        treefmt.config = {
          inherit (config.flake-root) projectRootFile;
          package = pkgs.treefmt;

          programs = formatters;
        };

        pre-commit.settings.hooks = formatters;
      };
    };

  /*

  outputs = {
    self,
    digga,
    nixpkgs,
    home-manager,
    impermanence,
    nixos-generators,
    nixos-hardware,
    nur,
    agenix,
    deploy,
    ...
  } @ inputs:
    digga.lib.mkFlake
    {
      inherit self inputs;

      channelsConfig = {
        allowUnfree = true;
      };

      # Not _really_ using digga's channel feature because I'm using nixpkgs-unstable for everything
      # That might change if I start using the stable Darwin release for anything
      channels = {
        nixpkgs = {
          imports = [];
          overlays = [];
        };
      };

      lib =
        import ./lib
        {
          lib = digga.lib // nixpkgs.lib;
        };

      # Overlays applied to all configs (I think?)
      sharedOverlays = [
        (final: prev: {
          __dontExport = true;
          # Unlike digga's devos example, this puts custom functions in the top level instead of scoping them under `our`
          lib = prev.lib.extend (lfinal: lprev: self.lib);
        })

        nur.overlay
        agenix.overlays.default
        (import ./pkgs)
      ];

      # NixOS configurations
      nixos = {
        hostDefaults = {
          system = "x86_64-linux";
          channelName = "nixpkgs";
          imports = [(digga.lib.importExportableModules ./modules)];
          modules = [
            # TODO: is this (or { lib = self.lib; }) necessary?
            # { lib.our = self.lib; }

            # TODO: adapt https://github.com/divnix/digga/blob/main/modules/bootstrap-iso.nix to use custom installer
            digga.nixosModules.bootstrapIso

            digga.nixosModules.nixConfig
            home-manager.nixosModules.home-manager
            agenix.nixosModules.age
          ];
        };

        # NixOS hosts are defined under ./hosts/nixos
        imports = [(digga.lib.importHosts ./hosts/nixos)];

        # Host-specific properties can also be defined here
        hosts = {
          faramir = {
            system = "aarch64-linux";
          };
          luthien = {};
          elessar = {};
          testvm = {};
        };

        # Set up profiles, portable users, and suites
        # See: https://digga.divnix.com/concepts/profiles.html
        #      https://digga.divnix.com/concepts/suites.html
        #      https://digga.divnix.com/concepts/users.html
        #      https://digga.divnix.com/api-reference-home.html#homeusers
        importables = rec {
          profiles = digga.lib.rakeLeaves ./profiles;
          users = digga.lib.rakeLeaves ./users/nixos;
          suites = import ./suites.nix {inherit profiles users;};
        };
      };

      # TODO: darwin configurations?

      # Individual user configurations
      home = {
        imports = [(digga.lib.importExportableModules ./users/modules)];
        # modules = [ impermanence.nixosModules.home-manager ];
        importables = rec {
          profiles = digga.lib.rakeLeaves ./users/profiles;
          suites = import ./users/suites.nix {inherit profiles;};
        };

        # Individual portable Home Manager users (NOT system users like root or nixos)
        users = digga.lib.rakeLeaves ./users/users;
        # TODO: figure out how to install these: could use deploy-rs, or I think they end up in self.hmUsers
      };

      # Developer shell for this repo
      devshell = {
        modules = [./shell];
      };

      deploy = {
        sshUser = "root";
        nodes = digga.lib.mkDeployNodes self.nixosConfigurations {
          testvm = {
            sshUser = "sysadmin";
            hostname = "localhost";
            sshOpts = ["-p" "2222" "-o" "UserKnownHostsFile=/dev/null" "-o" "StrictHostKeyChecking=no"];
            profilesOrder = ["system" "hm-ben"];
            profiles.hm-ben = {
              user = "ben";
              path = deploy.lib.x86_64-linux.activate.home-manager self.homeConfigurationsPortable.x86_64-linux.ben;
            };
          };
        };
      };
    };

  */
}
