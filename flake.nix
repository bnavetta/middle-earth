{
  description = "Ben's infrastructure, Nix edition";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.deploy-rs.url = "github:serokell/deploy-rs";

  inputs.nixos-generators = {
    url = "github:nix-community/nixos-generators";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.ragenix = {
    url = "github:yaxitech/ragenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.wedding-website = {
    url = "git+ssh://git@github.com/bnavetta/follettnavetta.wedding.git?ref=main";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, nixos-generators, flake-utils, deploy-rs, ragenix, wedding-website, home-manager, ... }:
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
}
