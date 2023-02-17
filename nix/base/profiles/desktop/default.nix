{inputs}: let
  inherit (inputs) nixpkgs-wayland;
in
  {
    config,
    lib,
    pkgs,
    ...
  }: let
    # TODO: look at gtkgreet styling per https://gitlab.com/kira-bruneau/nixos-config/-/blob/main/environment/desktop.nix
    gtkGreetSwayConfig = pkgs.writeText "gtkgreet-sway-config" ''
      bindsym Mod4+shift+e exec swaynag \
        -t warning \
        -m 'What do you want to do?' \
        -b 'Poweroff' 'systemctl poweroff' \
        -b 'Reboot' 'systemctl reboot'
      include /etc/sway/config.d/*
      exec "${pkgs.greetd.gtkgreet}/bin/gtkgreet -l; ${pkgs.sway}/bin/swaymsg exit"
    '';

    # Wrap gtkgreet in sway since it needs a Wayland compositor. Also use sway for power commands
    sessionCommand = pkgs.writeShellScript "gtkgreet-sway-launcher" ''
      export WLR_RENDERER_ALLOW_SOFTWARE=1
      # TODO: only really want this set for greeter
      export MESA_SHADER_CACHE_DIR="/tmp/mesa-shader-cache"
      systemd-cat --identifier gtkgreet-sway sway --config ${gtkGreetSwayConfig}
    '';

    waylandSession = pkgs.writeShellScriptBin "wayland-session" ''
      # See WayfireWM/wayfire#213 - hardware cursors are iffy in general / with NVIDIA
      export WLR_NO_HARDWARE_CURSORS=1
      /run/current-system/systemd/bin/systemctl --user start graphical-session.target
      /run/current-system/systemd/bin/systemd-cat --identifier "$1" "$@"
      /run/current-system/systemd/bin/systemctl --user stop graphical-session.target
    '';
  in {
    imports = [
      ./yubikey.nix
      ./audio.nix
      ./ios.nix
    ];

    environment.systemPackages = [
      waylandSession
      pkgs.wayland-utils
      pkgs.mesa
      pkgs.weston
      pkgs.vlc
      pkgs.google-chrome
      pkgs.okular
      nixpkgs-wayland.packages.wayfire-unstable
    ];

    programs.firefox.enable = true;
    programs._1password-gui.enable = true;

    # In addition to installing sway, applies NixOS-specific setup
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraOptions = ["--verbose" "--debug" "--unsupported-gpu"];
    };

    hardware.opengl.enable = true;
    hardware.opengl.extraPackages = [pkgs.mesa.drivers];

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = sessionCommand;
        };
      };
    };

    environment.etc."greetd/environments".text = ''
      wayland-session wayfire
      wayland-session sway
    '';

    # xdg-desktop-portal works by exposing a series of D-Bus interfaces
    # known as portals under a well-known name
    # (org.freedesktop.portal.Desktop) and object path
    # (/org/freedesktop/portal/desktop).
    # The portal interfaces include APIs for file access, opening URIs,
    # printing and others.
    services.dbus.enable = true;
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      # gtk portal needed to make gtk apps happy
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };

    # Silence warnings from LIBGL_DEBUG=verbose about a missing /etc/drirc config file
    environment.etc."drirc".text = ''<driconf></driconf>'';
  }
