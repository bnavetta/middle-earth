{
  inputs,
  cell,
}: let
  inherit (inputs.cells) base;
  inherit (cell) homeProfiles;
in {
  nixos = base.lib.mkModule "Ben's user configuration for NixOS" ({
    config,
    pkgs,
    ...
  }: {
    # Also set SSH keys for root?
    users.users.sysadmin.openssh.authorizedKeys.keys = cell.lib.sshKeys;

    users.users.ben = {
      # TODO: password file
      password = "ben";
      description = "Ben";
      isNormalUser = true;
      createHome = true;
      extraGroups = ["wheel" "libvirtd"];
      openssh.authorizedKeys.keys = cell.lib.sshKeys;
      shell = pkgs.zsh;
    };

    middle-earth.state.users.safe.ben = {
      directories = [
        {
          directory = ".ssh";
          mode = "0700";
        }
        {
          directory = ".gnupg";
          mode = "0700";
        }
        "Music"
        "Pictures"
        "Documents"
        "Videos"
      ];
    };

    middle-earth.state.users.local.ben = {
      directories = [
        "Downloads"
        ".cache"
        ".cargo"
        ".mozilla"
        ".config/google-chrome"
        ".config/Code"
      ];
      files = [
        ".zsh_history"
        ".bash_history"
      ];
    };

    home-manager.users.ben = {...}: {
      imports = [
        homeProfiles.common
        homeProfiles.desktop
        # base.homeProfiles.state
      ];
    };

    systemd.services.home-manager-ben.environment.VERBOSE = "1";
  });
}
