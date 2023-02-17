{
  inputs,
  cell,
}: {
  pkgs,
  lib,
  ...
}: let
in {
  home.packages = with pkgs; [
    doctl
    flyctl
    gh
    httpie
    hyperfine
    imagemagick
    just
    kubectl
  ];

  programs.git = {
    enable = true;

    userName = "Ben Navetta";
    userEmail = "ben.navetta@gmail.com";

    extraConfig = {
      diff.colorMoved = "default";
      init.defaultBranch = "main";
    };

    delta = {
      enable = true;
      options = {
        side-by-side = true;
        line-numbers = true;
        hyperlinks = true;
        navigate = true; # use n and N to move between files
        features = "zebra-dark"; # used for color-moved
      };
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.zsh = {
    enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

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
