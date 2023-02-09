{ inputs, cell }: {
  # groups.hosts = ["elessar"];

  secrets = [
    {
      path = "secrets/root.age";
      # identities = ["elessar"];
      groups = ["admins"];
    }
  ];
}