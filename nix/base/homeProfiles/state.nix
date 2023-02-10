{
  inputs,
  cell,
}: {
  config,
  nixosConfig,
  lib,
  ...
}: let
  inherit (inputs) impermanence;
  inherit (lib) attrValues mkOption mkMerge partition types;

  # TODO: may be better off replacing all of this with the system-level persistence users settings

  cfg = config.middle-earth.state;
  nixosCfg = nixosConfig.middle-earth.state;

  safeRoot = "${nixosCfg.safeRoot}/home/${config.home.username}";
  localRoot = "${nixosCfg.localRoot}/home/${config.home.username}";

  persistType = types.submodule ({config, ...}: {
    options = {
      safe = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Mark this as "safe" state, which should be backed up, instead of "local" state
        '';
      };

      method = mkOption {
        type = types.enum ["symlink" "bindfs"];
        default = "symlink";
        description = ''
          Linking method to use for this directory. The default is
          `symlink` (the opposite of the underlying impermanence module) for
          performance reasons (https://github.com/nix-community/impermanence/issues/42),
          but some programs will work better with `bindfs`.
        '';
      };

      path = mkOption {
        type = types.str;
        description = ''
          Path on the filesystem to this state.
        '';
      };
    };
  });

  impermanenceDirs = let
    mkImpermanenceDir = p: {
      inherit (p) method;
      directory = p.path;
    };
    bySafety = partition (p: p.safe) (attrValues cfg.persist);
  in {
    safe = map mkImpermanenceDir bySafety.right;
    local = map mkImpermanenceDir bySafety.wrong;
  };

  mkSafe = path: { inherit path; safe = true; };
in {
  imports = [
    impermanence.nixosModules.home-manager.impermanence
  ];

  options = {
    middle-earth.state = {
      persist = mkOption {
        type = types.attrsOf persistType;
      };

      files.safe = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Files to link to safe persistent storage";
      };

      files.local = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Files to link to local persistent storage";
      };
    };
  };

  config = mkMerge [
    {
      home.persistence."${safeRoot}" = {
        directories = impermanenceDirs.safe;
        files = cfg.files.safe;

        # Allow other users to access files through bind-mounted directories (e.g. for sudo, Docker/VMs)
        # This requires programs.fuse.userAllowOther = true at the system level
        allowOther = true;
      };
    }
    {
      home.persistence."${localRoot}" = {
        directories = impermanenceDirs.local;
        files = cfg.files.local;

        # Allow other users to access files through bind-mounted directories (e.g. for sudo, Docker/VMs)
        # This requires programs.fuse.userAllowOther = true at the system level
        allowOther = true;
      };
    }
    {
      middle-earth.state.persist = {
        ssh = mkSafe ".ssh";
        gpg = {
          path = ".gnupg";
          safe = true;
          method = "bindfs";
        };
        cache.path = ".cache";
        downloads.path = "Downloads";
        music = mkSafe "Music";
        pictures = mkSafe "Pictures";
        documents = mkSafe "Documents";
        videos = mkSafe "Videos";
      };

      middle-earth.state.files.local = [
        ".bash_history"
        ".zsh_history"
      ];
    }
  ];
}
