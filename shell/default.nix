{
  self,
  inputs,
  pkgs,
  lib,
  extraModulesPath,
  ...
}: let
  # devshell groups commands into categories
  commandIn = category: package: {inherit package category;};
  middleEarthCommand = commandIn "middle-earth";
in {
  imports = [
    # Enable devshell's git hook support
    "${extraModulesPath}/git/hooks.nix"
    ./git-hooks
  ];

  packages = with pkgs; [
    age
    age-plugin-yubikey
    alejandra
    cachix
    mkpasswd
    shfmt
    treefmt
    nodePackages.prettier
  ];

  commands =
    [
      {
        category = "middle-earth";
        name = "agenix";
        help = "age-encrypted secrets for NixOS";
        command = "cd $PRJ_ROOT; ${pkgs.ragenix}/bin/agenix --rules=./secrets/secrets.nix --identity=./secrets/age-yubikeys/keychain.txt $@";
      }
      {
        category = "middle-earth";
        name = "agepasswd";
        help = "Generate an age-encrypted password hash";
        command = "mkpasswd -m yescrypt | agenix --editor - --edit $@";
      }
      (middleEarthCommand pkgs.cachix)
      {
        category = "middle-earth";
        name = pkgs.nvfetcher.pname;
        help = pkgs.nvfetcher.meta.description;
        command = "cd $PRJ_ROOT/pkgs; ${pkgs.nvfetcher}/bin/nvfetcher -c ./sources.toml $@";
      }

      (commandIn "formatter" pkgs.treefmt)
    ]
    ++ lib.optionals (pkgs.stdenv.hostPlatform.isLinux && !pkgs.stdenv.buildPlatform.isDarwin) [
      # Linux-only commands
      (middleEarthCommand inputs.deploy.packages.${pkgs.system}.deploy-rs)
    ];
}
