/*
* User-specifc desktop configuration, such as i3 settings. This is NixOS-only.
*/
{pkgs, ...}: let
  # i3 workspace names
  i3Workspaces = {
    main = "1: Main";
    terminal = "2: Terminal";
    web = "3: Web";
    editor = "4: Editor";
    chat = "5: Chat";
    misc1 = "6: Misc";
    misc2 = "7: Misc 2";
  };
in {
  home.packages = with pkgs; [
    font-awesome
    overpass
    picom
  ];

  # TODO: home-manager can set up X keyboards, use for CapsLock binding

  services.dunst = {
    # TODO: other dunst settings
    enable = true;
    settings = {
      global.font = "Overpass Light 11";
    };
  };

  services.polybar = {
    enable = true;

    # Build Polybar with the i3 module
    package = pkgs.polybar.override {
      i3Support = true;
    };

    # The services.polybar module calls this from a systemd user unit that's part of tray.target
    script = "polybar main &";

    settings = let
      foregroundColor = "#fff";
      backgroundColor = "#222";
      focusColor = "#cfc55b";
      alertColor = "#d1324f";
      mkNetworkModule = {
        prefix,
        interface ? null,
        interfaceType ? null,
      }: {
        type = "internal/network";
        interface-type = lib.mkIf (interfaceType != null) interfaceType;
        interface = lib.mkIf (interface != null) interface;
        interval = 3.0;
        format.connected = "<label-connected>";
        format.disconnected = "<label-disconnected>";
        label = {
          connected = "${prefix}%local_ip%";
          disconnected = {
            text = "${prefix}%ifname% disconnected";
            foreground = alertColor;
          };
        };
      };
    in {
      "bar/main" = {
        width = "100%";
        height = 20;
        fixed-center = true;
        foreground = foregroundColor;
        background = backgroundColor;

        line.size = 3;
        line.color = "#f00";

        padding.left = 8;
        padding.right = 8;
        module.margin.left = 2;
        margin.module.right = 2;

        tray = {
          position = "right";
          padding.left = 8;
          padding.right = 8;
          maxsize = 32;
        };
        font = ["Overpass:size=12" "Font Awesome 6 Free Solid:style=Solid;0" "Font Awesome 6 Brands Regular:style=Regular;0"];

        modules = {
          left = "i3";
          center = "xwindow";
          right = "ethernet tailscale date";
        };
      };

      "module/xwindow" = {
        type = "internal/xwindow";
        label = "%title:0:120:...%";
      };

      "module/i3" = {
        type = "internal/i3";
        format = "<label-state> <label-mode>";
        index-sort = true;
        wrapping-scroll = true;
        strip-wsnumbers = true;

        ws-icon = [
          "${i3Workspaces.main};"
          "${i3Workspaces.terminal};"
          "${i3Workspaces.web};"
          "${i3Workspaces.editor};"
          "${i3Workspaces.chat};"
        ];
        ws-icon-default = "";

        # Only show workspaces on the same output as the bar
        pin.workspaces = true;

        label = let
          baseLabel = {
            text = "%icon%";
            padding = 4;
          };
        in {
          # TODO: what does label-mode do?

          # Active workspace on focused monitor
          focused = baseLabel // {foreground = focusColor;};
          # Inactive workspace on any monitor
          unfocused = baseLabel;
          # Active workspace on unfocused monitor
          visible = baseLabel // {foreground = focusColor;};
          # Any workspace with urgency hint set
          urgent = baseLabel // {foreground = alertColor;};

          separator = {
            text = "|";
            foreground = foregroundColor;
            padding = 0;
          };
        };
      };

      "module/ethernet" = mkNetworkModule {
        interfaceType = "wired"; # Find the first running wired interface
        prefix = " ";
      };

      "module/tailscale" = mkNetworkModule {
        interface = "tailscale0";
        prefix = " ";
      };

      "module/date" = {
        type = "internal/date";
        interval = 1;
        date = "%a %b %d";
        date-alt = "\${self.date}";
        time = "%l:%M %p";
        time-alt = "%l:%M:%S %p";
        label = "%date% %time%";
      };

      # TODO: wifi, pipewire, UPS
    };
  };

  # Home Manager xsession management must be enabled to generate tray.target, which binds to
  # graphical-session.target and loads polybar and other tray services.
  # However, the NixOS xsession wrapper will only run one of ~/.xsession and the xsession
  # script configured by the chosen .desktop file.
  #
  # As of https://github.com/nix-community/home-manager/pull/2123, Home Manager handles this
  # by running the session command passed down from the NixOS xsession wrapper, rather than
  # replacing it completely.
  #
  # Unfortunately, setting xsession.windowManager.i3.enable replaces this default with a
  # hardcoded i3 startup command.
  #
  # Disabling xsession.windowManager.i3.enable isn't a great option because that also stops
  # Home Manager from managing the i3 configuration and auto-reloading it.
  #
  # The solution? A custom window manager command that mirrors the default behavior but falls
  # back to i3.
  xsession.windowManager.command = lib.mkForce ''
    if [[ -n "$1" ]]; then
      eval "$@"
    else
      ${config.xsession.windowManager.i3.package}/bin/i3
    fi
  '';

  xsession.windowManager.i3 = {
    enable = true;

    config = let
      modifier = "Mod4";
      # TODO: alacritty doesn't work in the VM because no OpenGL?
      terminal = "${pkgs.alacritty}/bin/alacritty";

      wsIndex = name: let
        group = builtins.match "([[:digit:]]+):.+" "${name}";
      in
        if group == null
        then throw "Bad i3 workspace name: `${name}`"
        else builtins.elemAt group 0;
      wsBindings = (
        builtins.listToAttrs
        (lib.flatten (
          builtins.map (ws: [
            {
              name = "${modifier}+${wsIndex ws}";
              value = "workspace number ${ws}";
            }
            {
              name = "${modifier}+Shift+${wsIndex ws}";
              value = "move container to workspace number ${ws}";
            }
          ]) (builtins.attrValues i3Workspaces)
        ))
      );
    in {
      inherit modifier;
      inherit terminal;

      keybindings = lib.mkOptionDefault (wsBindings
        // {
          "${modifier}+Return" = "exec ${terminal}";

          # Use cursor keys to change focus and move windows
          "${modifier}+Left" = "focus left";
          "${modifier}+Down" = "focus down";
          "${modifier}+Up" = "focus up";
          "${modifier}+Right" = "focus right";
          "${modifier}+Shift+Left" = "move left";
          "${modifier}+Shift+Right" = "move right";
          "${modifier}+Shift+Up" = "move up";
          "${modifier}+Shift+Down" = "move down";

          # Toggle fullscreen for the focused container
          "${modifier}+f" = "fullscreen toggle";

          # Enter notification mode
          "${modifier}+n" = "mode notifications";

          # Logout panel (TODO: replace with desk-exit-screen)
          "${modifier}+q" = "exec xfce4-session-logout";
        });

      modes = lib.mkOptionDefault {
        # Mode to manage notifications
        notifications = {
          Space = "exec --no-startup-id dunstctl context";
          h = "exec --no-startup-id dunstctl history-pop";
          x = "exec --no-startup-id dunstctl close";
          "Shift+x" = "exec --no-startup-id dunstctl close-all";
          # Return to normal
          Return = "mode default";
          Escape = "mode default";
          "${modifier}+n" = "mode default";
        };
      };

      # Workspace management
      workspaceLayout = "tabbed";
      # If you switch from workspace X to workspace Y with $mod+Y, pressing $mod+Y again will bring you back to workspace X
      workspaceAutoBackAndForth = true;

      fonts = {
        names = ["Overpass"];
        size = 10.0;
      };

      startup = [
        # Example from the docs, makes sense since an i3 restart usually means polybar needs to reload too
        {
          command = "systemctl --user restart polybar";
          always = true;
          notification = false;
        }
        {command = "firefox";}
        {command = terminal;}
      ];

      assigns = {
        "${i3Workspaces.web}" = [
          {class = "^(F|f)irefox$";}
        ];
        "${i3Workspaces.terminal}" = [
          {class = "^Alacritty$";}
        ];
      };

      bars = []; # Using Polybar instead
    };
  };
}
