{
  inputs,
  cell,
}: {
  identities.ben = "age1yubikey1q0janequt0yrz9jdzy70en89gw626hfh3amgm404g55q5agev47qvrutcdh";
  groups.admins = ["ben"];

  secrets = [
    {
      path = "secrets/password.age";
      groups = ["admins"];
      identities = ["elessar"];
    }
  ];
}
