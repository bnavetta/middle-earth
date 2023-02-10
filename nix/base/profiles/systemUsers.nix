# Set up system users. If running in the test VM, they will be given static passwords because the VM doesn't have access to agenix secrets.
{
  config,
  pkgs,
  lib,
  options,
  ...
}: let
  inherit (lib) mkIf mkMerge hasAttr;

  isInVM = options ? microvm;

  coreConfig = {
    users.mutableUsers = false;

    users.users.sysadmin = {
      isNormalUser = true;
      extraGroups = ["wheel"];
    };
  };

  # Config that can't be applied to VMs
  mainConfig = {
    age.secrets.rootPassword.file = ../../${config.networking.hostName}/secrets/root.age;
    age.secrets.sysadminPassword.file = ../secrets/sysadmin_password.age;
    users.users.root.passwordFile = config.age.secrets.rootPassword.path;
    users.users.sysadmin.passwordFile = config.age.secrets.sysadminPassword.path;
  };
in
  mkMerge [
    coreConfig
    (mkIf (!isInVM) mainConfig)
  ]
