{inputs}: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) attrValues;
  inherit (lib) mdDoc mkOption mkMerge mkIf types filter partition;
  cfg = config.middle-earth.state;

  persistPath = name: safe:
    if safe
    then "${cfg.safeRoot}/${name}"
    else "${cfg.localRoot}/${name}";

  persistType = types.submodule ({config, ...}: {
    options = {
      name = mkOption {
        type = types.str;
        default = config._module.args.name;
        description = ''
          Name of the directory used under the persistent state root
        '';
      };

      safe = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Mark this as "safe" state, which should be backed up, instead of "local" state
        '';
      };

      mode = mkOption {
        type = types.str;
        default = "0755";
        description = ''
          Permissions mode for the state directory in a format understood by chmod.
        '';
      };

      user = mkOption {
        type = types.str;
        default = "0";
        description = ''
          Owner of the state.
        '';
      };

      group = mkOption {
        type = types.str;
        default = "0";
        description = ''
          Group of the state.
        '';
      };

      path = mkOption {
        type = types.path;
        default = persistPath config.name config.safe;
        description = ''
          Path on the filesystem to this state.
        '';
      };
    };
  });

  impermanenceDirs = let
    # Find directories pointed to another location
    reroutedConfigs = filter (p: p.path != persistPath p.name p.safe) (attrValues cfg.persist);
    mkImpermanenceDir = p: {
      inherit (p) user group mode;
      directory = p.path;
    };
    bySafety = partition (p: p.safe) reroutedConfigs;
  in {
    safe = map mkImpermanenceDir bySafety.right;
    local = map mkImpermanenceDir bySafety.wrong;
  };
in {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  options = {
    middle-earth.state = {
      rootfsSize = mkOption {
        type = types.str;
        default = "1G";
        example = "1G";
        description = "Size of the root temporary filesystem";
      };

      mode = mkOption {
        type = types.enum ["zfs" "onefs"];
        default = "zfs";
        example = "zfs";
        description = mdDoc ''
          Partition layout for state.

          If `zfs`, then ZFS filesystems are configured for the Nix store, backed-up state, and local state.

          If `onefs`, then a single filesystem partition is used for all state and this module does not
          configure persistence for the Nix store.
        '';
      };

      persist = mkOption {
        type = types.attrsOf persistType;
      };

      zfs.parent = mkOption {
        type = types.str;
        default = "rpool";
        example = "mypool/parent/dataset";
        description = mdDoc ''
          Path to the ZFS storage pool (and optionally, parent dataset), to put state datasets in.
        '';
      };

      users = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Users who need persistent state directories
        '';
      };

      safeRoot = mkOption {
        type = types.str;
        default =
          if cfg.mode == "zfs"
          then "/persist/safe"
          else "/persist";
        internal = true;
      };

      localRoot = mkOption {
        type = types.str;
        default =
          if cfg.mode == "zfs"
          then "/persist/local"
          else "/persist";
        internal = true;
      };
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = (cfg.mode == "onefs") -> (lib.hasAttr "/persist" config.fileSystems);
          message = ''
            In `onefs` mode, there must be a persistent filesystem at `/persist`
          '';
        }
      ];

      fileSystems."/" = {
        device = "none";
        fsType = "tmpfs";
        options = ["defaults" "size=${cfg.rootfsSize}" "mode=755"];
        neededForBoot = true;
      };

      # Build an activation script for directories that were not relocated and can just be created outright.
      system.activationScripts."createDirectPersistentStorageDirs" = let
        directConfigs = filter (p: p.path == persistPath p.name p.safe) (attrValues cfg.persist);
        # TODO: this could be more robust
        installCmds = map (p: "mkdir -m ${p.mode} -p ${p.path} && chown ${p.user}:${p.group} ${p.path}") directConfigs;
      in {
        text = builtins.concatStringsSep "\n" installCmds;
      };
      # So that the identity file is available (agenixInstall is not defined if no secrets are in use)
      system.activationScripts.agenixInstall = mkIf (config.age.secrets != {}) {
        deps = ["createDirectPersistentStorageDirs"];
      };

      # Needed for user-level persistence
      programs.fuse.userAllowOther = true;
    }

    (mkIf (cfg.mode
      == "zfs") {
      fileSystems."/nix" = {
        device = "${cfg.zfs.parent}/local/nix";
        fsType = "zfs";
        neededForBoot = true;
      };

      fileSystems."${cfg.localRoot}" = {
        device = "${cfg.zfs.parent}/local/persist";
        fsType = "zfs";
        neededForBoot = true;
      };

      fileSystems."${cfg.safeRoot}" = {
        device = "${cfg.zfs.parent}/safe/persist";
        fsType = "zfs";
        neededForBoot = true;
      };

      environment.persistence."${cfg.localRoot}" = {
        hideMounts = true;
        directories = impermanenceDirs.local;
      };
      environment.persistence."${cfg.safeRoot}" = {
        hideMounts = true;
        directories = impermanenceDirs.safe;
      };

      # middle-earth.state.persist = lib.listToAttrs (lib.map (name: {
      #   inherit name;
      #   value = {
      #     user = name;
      #     group = name;
      #   };
      # }) cfg.users);
    })

    (mkIf (cfg.mode
      == "onefs") {
      fileSystems."${cfg.localRoot}".neededForBoot = lib.mkForce true;

      # No distinction between local and safe
      environment.persistence."${cfg.localRoot}" = {
        hideMounts = true;
        directories = impermanenceDirs.local ++ impermanenceDirs.safe;
      };
    })

    # Default persistence settings
    {
      
      middle-earth.state.persist = let
        mkEntry = safe: name: {
          name = if safe then "${name}-safe" else "${name}-local";
          value = {
            inherit name;
            user = name;
            group = name;
          };
        };
        userSafe = map (mkEntry true) cfg.users;
        userLocal = map (mkEntry false) cfg.users;
      in lib.listToAttrs (userSafe ++ userLocal);
    }
  ];

  # TODO: support non-ZFS for RPi
  # https://www.reddit.com/r/linuxhardware/comments/umk511/best_file_system_for_microsd_used_for_snapshots/
  # maybe by just having a single F2FS filesystem mounted at /persist
  # translation layer over impermanence can handle that vs safe/local divide
  # this module can have 2 modes:
  # - ZFS managed by the module
  # - a single FS configured externally, with bind mounts for /nix and state redirected to the /persist volume

  # for state directory/file config, use an agenix-like approach:
  # - declare named logical state
  # - by default, it just exists in the right persistent dir and its path config can be referenced in other modules
  # - if an explicit path is provided (i.e. path isn't default?), it generates an impermanence bind mount
}
