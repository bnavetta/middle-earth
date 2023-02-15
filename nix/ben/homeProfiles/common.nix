{
  inputs,
  cell,
}: {...}: {
  # TODO: set up shell, git, bpb, etc

  home.stateVersion = "23.05";
  programs.home-manager.enable = true;
}
