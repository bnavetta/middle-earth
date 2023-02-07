{
  hmUsers,
  config,
  lib,
  ...
}: {
  # home-manager.users = { inherit (hmUsers) ben; };

  age.secrets.benPassword.file = ../../secrets/ben_password.age;

  users.users.ben = {
    # passwordFile = config.age.secrets.benPassword.path;
    # TODO: set up testvm toggle
    password = "ben";
    description = "Ben";
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = lib.identities.users.ben.ssh;
  };
}
