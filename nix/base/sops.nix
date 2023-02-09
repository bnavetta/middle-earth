{
  inputs,
  cell,
}: {
  rules = [
    {
      pathRegex = "secrets/[^/]+\.yaml";
      users = ["ben"];
      hosts = ["*"];
    }
  ];
}