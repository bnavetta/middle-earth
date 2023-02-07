{
  profiles,
  pkgs,
  lib,
  ...
}: let
  # extraImports = builtins.trace pkgs.stdenv.hostPlatform.isDarwin [];
  # if pkgs.stdenv.hostPlatform.isLinux
  # then [profiles.nix-desktop]
  # else if pkgs.stdenv.hostPlatform.isDarwin
  # then []
  # else [];
in {
  home.stateVersion = "23.05";

  # imports = [profiles.shell profiles.nix-desktop]; # ++ extraImports;

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    bat
    btop
    exa
  ];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.zsh = {
    enable = true;

    shellAliases = {
      ls = "exa --classify --color-scale --git -g --icons";
      cat = "bat";
    };
  };

  programs.starship = {
    enable = true;

    settings = {
      add_newline = true;
      format = lib.concatStrings [
        "$directory"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_status"
        "$package"
        "$java"
        "$nodejs"
        "$python"
        "$rust"
        "$nix_shell"
        "$line_break"
        "$cmd_duration"
        "$jobs"
        "$username"
        "$hostname"
        "$character"
      ];

      cmd_duration.show_milliseconds = true;

      directory.fish_style_pwd_dir_length = 1;

      hostname.ssh_only = false;
      hostname.format = "@[\$hostname](\$style) ";
      username.show_always = true;
      username.format = "[\$user](\$style)";
    };
  };
}
