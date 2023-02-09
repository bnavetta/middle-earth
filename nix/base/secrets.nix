{
  inputs,
  cell,
}: {
  groups.hosts = [];

  paths = [
    {
      glob = "nix/base/secrets/*";
      identities = ["ben"];
      groups = ["hosts"];
    }
  ];
}
