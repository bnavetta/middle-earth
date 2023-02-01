# Set up system users
{
  config,
  pkgs,
  lib,
  ...
}: {
  age.secrets.rootPassword.file = ../../secrets/${config.networking.hostName}/root.age;

  users.users.root = {
    passwordFile = config.age.secrets.rootPassword.path;

    # openssh.authorizedKeys.keys = identities.users.ben.ssh;
  };

  age.secrets.sysadmin_password.file = ../../secrets/sysadmin_password.age;

  # Administrative user to preconfigure on all hosts
  users.users.sysadmin = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    passwordFile = config.age.secrets.sysadmin_password.path;
    openssh.authorizedKeys.keys = lib.identities.users.ben.ssh;
  };
}
