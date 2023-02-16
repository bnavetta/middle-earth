{
  inputs,
  cell,
}: {
  identities.elessar = "age1ew399uj73juvv30jvw6gddklyhzju9cnnq5eq6g6llvrrlxvcc8q5jnat5";
  groups.hosts = ["elessar"];

  secrets = [
    {
      path = "secrets/root.age";
      identities = ["elessar"];
      groups = ["admins"];
    }
  ];
}
