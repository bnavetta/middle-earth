# Set up system users
{
  config,
  pkgs,
  ...
}: {
  age.secrets.rootPassword.file = ../../secrets/${config.networking.hostName}/root.age;

  users.users.root = {
    passwordFile = config.age.secrets.rootPassword.path;
  };
}
