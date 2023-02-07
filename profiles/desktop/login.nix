# Login setup (greeter, desktop manager, etc.)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  waylandPkgs = inputs.nixpkgs-wayland.packages.${pkgs.system};

  # Partially adapted from https://gitlab.com/kira-bruneau/nixos-config/-/blob/main/environment/desktop.nix

  gtkGreetStyle = pkgs.writeText "gtkgreet.css" ''
    * {
      color: #eee;
      text-shadow: 1px 1px 2px #233;
    }

    #clock {
      margin-bottom: 4px;
    }

    entry {
      color: #444;
      text-shadow: none;
      box-shadow: 1px 1px 2px #233;
      border-width: 2px;
      padding: 4px 8px;
      background-color: #eee;
    }

    button {
        box-shadow: 1px 1px 2px #233;
        border-width: 2px;
        padding: 8px;
        background-color: #eee;
    }

    button * {
        color: #444;
        text-shadow: none;
    }

    body {
        padding-bottom: 4px;
    }

    combobox button {
        box-shadow: none;
        padding: 4px;
    }

    button.suggested-action * {
        color: #eee;
    }
  '';

  gtkGreetSwayConfig = pkgs.writeText "gtkgreet-sway-config" ''
    bindsym Mod4+shift+e exec swaynag \
      -t warning \
      -m 'What do you want to do?' \
      -b 'Poweroff' 'systemctl poweroff' \
      -b 'Reboot' 'systemctl reboot'
    include /etc/sway/config.d/*
    exec "${pkgs.greetd.gtkgreet}/bin/gtkgreet -l; ${pkgs.sway}/bin/swaymsg exit"
  '';
  # add -s ${gtkGreetStyle}; to gtkgreet command for styling

  # Wrap gtkgreet in sway since it needs a Wayland compositor. Also use sway for power commands
  sessionCommand = pkgs.writeShellScript "gtkgreet-sway-launcher" ''
    export WLR_RENDERER_ALLOW_SOFTWARE=1
    # TODO: only really want this set for greeter
    export MESA_SHADER_CACHE_DIR="/tmp/mesa-shader-cache"
    systemd-cat --identifier gtkgreet-sway sway --config ${gtkGreetSwayConfig}
  '';

  waylandSession = pkgs.writeShellScriptBin "wayland-session" ''
    /run/current-system/systemd/bin/systemctl --user start graphical-session.target
    /run/current-system/systemd/bin/systemd-cat --identifier "$1" "$@"
    /run/current-system/systemd/bin/systemctl --user stop graphical-session.target
  '';
  # cage = pkgs.cage.overrideAttrs (final: prev: {
  #   # Use a debug build to enable wlroots debug logging
  #   mesonBuildType = "debug";
  # });
in {
  environment.systemPackages = [
    waylandSession
    pkgs.wayland-utils
    pkgs.mesa
    pkgs.weston
    waylandPkgs.wayfire-unstable
  ];

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

  # Silence warnings from LIBGL_DEBUG=verbose about a missing /etc/drirc config file
  environment.etc."drirc".text = ''<driconf></driconf>'';
}
