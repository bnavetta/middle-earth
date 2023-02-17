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

    age.secrets.ben_password.file = ./secrets/password.age;

    users.users.ben = {
      passwordFile = config.age.secrets.ben_password.path;
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
        "src"
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
        ".local/share/direnv/allow"
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
        homeProfiles.shell
      ];
    };

    systemd.services.home-manager-ben.environment.VERBOSE = "1";
  });
}
