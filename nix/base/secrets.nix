{
  inputs,
  cell,
}: {
  groups.hosts = [];

  secrets = [
    {
      path = "secrets/sysadmin_password.age";
      groups = ["hosts" "admins"];
    }
    {
      path = "secrets/pastafi.age";
      identities = ["elessar"];
      groups = ["admins"]; # TODO: lan group?
    }
  ];
}
