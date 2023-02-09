{
  inputs,
  cell,
}: {
  user = {
    keys = [
      "age1yubikey1q0janequt0yrz9jdzy70en89gw626hfh3amgm404g55q5agev47qvrutcdh"
    ];
  };

  rules = [
    {
      pathRegex = "secrets/[^/]+\.yaml$";
      users = ["ben"];
    }
  ];
}