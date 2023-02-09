{
  inputs,
  cell,
}: {
  groups.hosts = [];

  secrets = [{
    path = "secrets/sysadmin_password.age";
    groups = ["hosts" "admins"];
  }];
}
