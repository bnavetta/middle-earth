{
  description = "Ben's infrastructure, Nix edition";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.deploy-rs.url = "github:serokell/deploy-rs";

  inputs.agenix = {
    url = "github:ryantm/agenix";
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

  outputs = { self, nixpkgs, nixos-hardware, flake-utils, deploy-rs, agenix, wedding-website, home-manager, ... }:
    let
      inherit (nixpkgs.lib) filterAttrs nixosSystem;
      inherit (builtins) readDir readFile mapAttrs;

      # Function to produce a NixOS system
      mkSystem = name: config:
        let
          sysModules = builtins.filter builtins.pathExists [ ./hosts/${name}/hardware-configuration.nix ./hosts/${name}/networking.nix ];
          extraModules = if config ? extraModules then config.extraModules else [ ];
        in
        nixosSystem rec {
          system = config.system;

          modules = [
            ./lib/modules/common.nix
            ./lib/modules/containers.nix
            agenix.nixosModule
            home-manager.nixosModules.home-manager
            ./lib/modules/auto-update.nix
            ({ ... }: {
              networking.hostName = if config ? hostname then config.hostname else name;
              system = {
                stateVersion = config.stateVersion;
                # Bake the repository's git revision into the system
                configurationRevision = self.sourceInfo.rev;
              };

              # See https://www.tweag.io/blog/2020-07-31-nixos-flakes/
              # This pins nixpkgs to the version the system was built with
              nix.registry.nixpkgs.flake = nixpkgs;
            })
          ] ++ extraModules ++ sysModules;
        };


      hosts = mapAttrs
        (name: typ: assert typ == "directory"; import ./hosts/${name} {
          localModules = ./lib/modules;
          flakes = { inherit wedding-website nixos-hardware; };
          inherit flake-utils;
        })
        (readDir ./hosts);
    in
    {
      # Create NixOS configurations and deploy-rs nodes for each host
      nixosConfigurations = mapAttrs mkSystem hosts;

      deploy.nodes = mapAttrs
        (name: config: {
          hostname = name;
          profiles.system = {
            user = "root";
            sshUser = "root";
            path = deploy-rs.lib.${config.system}.activate.nixos self.nixosConfigurations.${name};
          };
          # Nix can't cross-build, so build on the remote system if it's not compatible with the deploy machine
          # https://discourse.nixos.org/t/problem-with-remote-building-on-different-architecture/11446/2
          # remoteBuild = config.system != flake-utils.lib.system.x86_64-linux;
        })
        hosts;

      # Checks don't work with remote builds https://github.com/serokell/deploy-rs/issues/167#issuecomment-1326841159
      # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            terraform
            age-plugin-yubikey

            deploy-rs.packages.${system}.deploy-rs

            agenix.defaultPackage.${system}
          ];
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
