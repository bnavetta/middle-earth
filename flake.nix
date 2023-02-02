{
  description = "Ben's infrastructure, Nix edition";

  # nix.conf options set while evaluating this flake
  nixConfig = {
    extra-experimental-features = "nix-command flakes";
    extra-substituters = [
      "https://nrdxp.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-utils.url = "github:numtide/flake-utils";

    # Only use latest NixOS
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    digga = {
      url = "github:divnix/digga";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixlib.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        deploy.follows = "deploy";
      };
    };

    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:bnavetta/ragenix?ref=remove-header-function";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wedding-website = {
      url = "git+ssh://git@github.com/bnavetta/follettnavetta.wedding.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO: also add LnL7/nix-darwin if applicable
  };

  outputs = {
    self,
    digga,
    nixpkgs,
    home-manager,
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
            # digga.nixosModules.bootstrapIso

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
        };

        # Set up profiles, portable users, and suites
        # See: https://digga.divnix.com/concepts/profiles.html
        #      https://digga.divnix.com/concepts/suites.html
        #      https://digga.divnix.com/concepts/users.html
        #      https://digga.divnix.com/api-reference-home.html#homeusers
        importables = rec {
          profiles = digga.lib.rakeLeaves ./profiles;
          suites = import ./suites.nix {inherit profiles;};
        };
      };

      # TODO: darwin configurations?

      # Individual user configurations
      home = {
        imports = [(digga.lib.importExportableModules ./users/modules)];
        modules = [];
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
        nodes = digga.lib.mkDeployNodes self.nixosConfigurations {};
      };
    };

  /*
  let
  inherit (nixpkgs.lib) filterAttrs nixosSystem;
  inherit (builtins) readDir readFile mapAttrs filter pathExists hasAttr;

  # Produces a root NixOS module that encapsulates all the config for a system. This module can be used to either build a system (with `nixosSystem`)
  # or build a disk image (using `nixosGenerate`).
  mkRootModule = name: config:
  let
  extraModules = if config ? extraModules then config.extraModules else [ ];
  in
  {
  imports = [
  ./lib/modules/common.nix
  ./lib/modules/containers.nix
  ./lib/modules/auto-update.nix
  ragenix.nixosModules.age
  home-manager.nixosModules.home-manager
  {
  networking.hostName = if config ? hostname then config.hostname else name;
  system = {
  stateVersion = config.stateVersion;
  # Bake the repository's git revision into the system
  configurationRevision = if (hasAttr "rev" self.sourceInfo) then self.sourceInfo.rev else "dirty";
  };

  # See https://www.tweag.io/blog/2020-07-31-nixos-flakes/
  # This pins nixpkgs to the version the system was built with
  nix.registry.nixpkgs.flake = nixpkgs;
  }
  ] ++ extraModules;
  };


  systems = mapAttrs
  (name: sys: sys.loadConfig {
  localModules = ./lib/modules;
  flakes = { inherit wedding-website nixos-hardware; };
  inherit flake-utils;
  })
  (import ./lib/systems.nix);
  in
  {
  # Create NixOS configurations and deploy-rs nodes for each host
  nixosConfigurations = mapAttrs
  (name: config:
  # Only include hardware configuration for NixOS configs, not when producing disk images
  let sysModules = filter pathExists [ ./systems/${name}/hardware-configuration.nix ./systems/${name}/networking.nix ]; in
  nixosSystem
  {
  system = config.system;
  modules = [ (mkRootModule name config) ] ++ sysModules;
  })
  systems;

  deploy.nodes = mapAttrs
  (name: config: {
  hostname = name;
  profiles.system = {
  user = "root";
  sshUser = "root";
  path = deploy-rs.lib.${config.system}.activate.nixos self.nixosConfigurations.${name};
  };
  })
  systems;

  packages.x86_64-linux.luthien-image =
  let
  config = systems.luthien; in
  nixos-generators.nixosGenerate
  {
  system = config.system;
  modules = [ (mkRootModule "luthien" config) ];
  format = "do";
  };

  # Checks don't work with remote builds https://github.com/serokell/deploy-rs/issues/167#issuecomment-1326841159
  # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  } // flake-utils.lib.eachDefaultSystem (system:
  let
  pkgs = nixpkgs.legacyPackages.${system};
  in
  {
  devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
  age
  terraform
  age-plugin-yubikey

  deploy-rs.packages.${system}.deploy-rs

  ragenix.packages.${system}.default
  ];
  };

  formatter = pkgs.nixpkgs-fmt;
  }
  );

  */
}
