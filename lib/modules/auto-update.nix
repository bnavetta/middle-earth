# Auto-update configuration
{ ... }: {

  # See https://www.reddit.com/r/NixOS/comments/negjsu/comment/gyhbrm4/
  # This auto-updates daily, fetching the latest Flake contents from GitHub
  # A GitHub Action automatically updates the Flake lock file, so the next auto-update will pull in new package versions.
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    flake = "git+ssh://git@github.com/bnavetta/middle-earth.git";
    flags = [
      "--show-trace"
      "-L"
    ];
    dates = "daily";
  };

  home-manager.users.root = ({ ... }: {
    home.username = "root";
    home.homeDirectory = "/root";

    home.stateVersion = "22.11";

    programs.home-manager.enable = true;

    # Configure the root user to use the host key for SSH
    # Then, we can add this key to private GitHub repos to enable the machine to fetch them
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "github.com" = {
          identityFile = "/etc/ssh/ssh_host_ed25519_key";
        };
      };
    };
  });
}
