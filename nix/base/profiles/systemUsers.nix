# Set up system users. If running in the test VM, they will be given static passwords because the VM doesn't have access to agenix secrets.
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkMerge;

  # This is kind of janky - maybe use an option instead?
  # isTestVM = config.networking.hostName == "testvm";
  isTestVM = false;

  coreConfig = {
    # Also set SSH keys for root?
    users.users.sysadmin = {
      isNormalUser = true;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = lib.identities.users.ben.ssh;
    };
  };

  testConfig = {
    users.users.root.password = "root";
    users.users.sysadmin.password = "sysadmin";

    warnings = [
      ''
        Detected a test VM. Using testing passwords instead of agenix-configured ones
      ''
    ];
  };

  mainConfig = {
    age.secrets.rootPassword.file = ../../../secrets/${lib.traceVal config.networking.hostName}/root.age;
    age.secrets.sysadminPassword.file = ../../../secrets/sysadmin_password.age;
    users.users.root.passwordFile = config.age.secrets.rootPassword.path;
    users.users.sysadmin.passwordFile = config.age.secrets.sysadminPassword.path;
  };
in
  mkMerge [
    coreConfig
    (mkIf isTestVM testConfig)
    (mkIf (!isTestVM) mainConfig)
  ]
