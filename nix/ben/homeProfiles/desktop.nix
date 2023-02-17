{
  inputs,
  cell,
}: {
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (inputs) nixpkgs-wayland nixago;

  # Pass along important desktop environment variables to systemd services and the D-Bus environment. This is needed for pinentry and other background tasks to work.
  # Adapted from:
  # - https://gitlab.archlinux.org/bot-test/packages/sway/-/blob/main/50-systemd-user.conf
  # - https://nixos.wiki/wiki/Sway
  # - https://github.com/nix-community/home-manager/blob/da72e6fc6b7dc0c3f94edbd310aae7cd95c678b5/modules/services/window-managers/i3-sway/sway.nix#L320
  updateSystemdEnvironment = pkgs.writeShellScript "update-systemd-environment" ''
    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wayfire XDG_SESSION_TYPE
    # This is implied by the --systemd flag
    # ${pkgs.systemd}/bin/systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wayfire XDG_SESSION_TYPE
  '';

  # Not using std's nixago support so that this can be defined in terms of Home Manager packages+options
  # Could revisit in the future
  wayfireConfig = nixago.lib.make {
    # Take the tutorial to get started.
    # https://github.com/WayfireWM/wayfire/wiki/Tutorial
    #
    # Read the Configuration document for a complete reference.
    # https://github.com/WayfireWM/wayfire/wiki/Configuration
    configData = {
      core = {
        plugins = lib.concatStringsSep " " [
          "alpha"
          "animate"
          "autostart"
          "command"
          "cube"
          "decoration"
          "expo"
          "fast-switcher"
          "fisheye"
          # Added recently
          # "foreign-toplevel"
          "grid"
          # Added recently
          # "gtk-shell"
          "idle"
          "invert"
          "move"
          "oswitch"
          "place"
          "resize"
          "switcher"
          "vswitch"
          "window-rules"
          "wm-actions"
          "wobbly"
          "wrot"
          "zoom"
        ];

        # Close the focused window
        close_top_view = "<super> KEY_Q | <alt> KEY_F4";

        # Arrange workspaces into a 3x3 grid
        vwidth = 3;
        vheight = 3;

        # Prefer client-side decorations over server-side decorations
        preferred_decoration_mode = "client";
      };

      # Mouse bindings
      move.activate = "<super> BTN_LEFT"; # Drag windows with Super + left mouse button
      resize.activate = "<super> BTN_RIGHT"; # Resize windows with Super + right mouse button
      zoom.modifier = "<super>"; # Zoom in the desktop by scrolling with Super
      alpha.modifier = "<super> <alt>"; # Change opacity by scrolling with Super + Alt
      wrot.activate = "<super> <ctrl> BTN_RIGHT"; # Rotate windows with the mouse
      fisheye.toggle = "<super> <ctrl> KEY_F"; # Fisheye effect

      # Startup commands
      autostart = {
        # Automatically start background and panel (wf-backgroumd, wf-panel, and wf-dock)
        autostart_wf_shell = true;

        # Output configuration
        # https://wayland.emersion.fr/kanshi/
        outputs = lib.getExe nixpkgs-wayland.packages.kanshi;

        # Notifications
        # https://wayland.emersion.fr/mako/
        notifications = lib.getExe nixpkgs-wayland.packages.mako;

        # Screen color temperature
        # https://sr.ht/~kennylevinsen/wlsunset/
        gamma = lib.getExe nixpkgs-wayland.packages.wlsunset;

        # Idle configuration
        # https://github.com/swaywm/swayidle
        # https://github.com/swaywm/swaylock
        idle = "${lib.getExe nixpkgs-wayland.packages.swayidle} before-sleep ${lib.getExe nixpkgs-wayland.packages.swaylock}";

        systemd_env = lib.getExe updateSystemdEnvironment;

        # XDG desktop portal
        # Needed by some GTK applications
        # TODO: I think this needs some extra setup for NixOS?
        portal = "/usr/libexec/xdg-desktop-portal";
      };

      # This will lock your screen after 300 seconds of inactivity, then turn off
      # your displays after another 300 seconds.
      # Disables the compositor going idle with Super + z.
      idle = {
        screensaver_timeout = 300;
        dpms_timeout = 600;
        toggle = "<super> KEY_Z";
      };

      # Application bindings
      command = {
        binding_terminal = "<super> KEY_ENTER";
        command_terminal = "${lib.getExe pkgs.alacritty}";

        # Start your launcher
        # https://hg.sr.ht/~scoopta/wofi
        # Note: Add mode=run or mode=drun to ~/.config/wofi/config.
        # You can also specify the mode with --show option.
        binding_launcher = "<super> <shift> KEY_ENTER";
        command_launcher = lib.getExe nixpkgs-wayland.packages.wofi;

        # Screen locker
        # https://github.com/swaywm/swaylock
        binding_lock = "<super> <shift> KEY_ESC";
        command_lock = lib.getExe nixpkgs-wayland.packages.swaylock;

        # Logout
        # https://github.com/ArtsyMacaw/wlogout
        binding_logout = "<super> KEY_ESC";
        command_logout = lib.getExe nixpkgs-wayland.packages.wlogout;

        # Screenshots
        # https://wayland.emersion.fr/grim/
        # https://wayland.emersion.fr/slurp/
        binding_screenshot = "KEY_PRINT";
        command_screenshot = "{{ lib.getExe nixpkgs-wayland.packages.grim }} $(date '+%F_%T').webp";
        binding_screenshot_interactive = "<shift> KEY_PRINT";
        command_screenshot_interactive = "${lib.getExe nixpkgs-wayland.packages.slurp} | ${lib.getExe nixpkgs-wayland.packages.grim} -g - $(date '+%F_%T').webp";

        # Volume controls
        # https://alsa-project.org
        # TODO: set up with pipewire
        # repeatable_binding_volume_up = KEY_VOLUMEUP
        # command_volume_up = amixer set Master 5%+
        # repeatable_binding_volume_down = KEY_VOLUMEDOWN
        # command_volume_down = amixer set Master 5%-
        # binding_mute = KEY_MUTE
        # command_mute = amixer set Master toggle

        # Screen brightness
        # https://haikarainen.github.io/light/
        # TODO: set this up (can install system-wide)
        # repeatable_binding_light_up = KEY_BRIGHTNESSUP
        # command_light_up = light -A 5
        # repeatable_binding_light_down = KEY_BRIGHTNESSDOWN
        # command_light_down = light -U 5
      };

      # Window management
      wm-actions = {
        toggle_fullscreen = "<super> KEY_F";
        toggle_always_on_top = "<super> KEY_X";
        toggle_sticky = "<super> <shift> KEY_X";
      };

      # Position the windows in certain regions of the output.
      grid = {
        #
        # ⇱ ↑ ⇲   │ 7 8 9
        # ← f →   │ 4 5 6
        # ⇱ ↓ ⇲ d │ 1 2 3 0
        # ‾   ‾
        slot_bl = "<super> KEY_KP1";
        slot_b = "<super> KEY_KP2";
        slot_br = "<super> KEY_KP3";
        slot_l = "<super> KEY_LEFT | <super> KEY_KP4";
        slot_c = "<super> KEY_UP | <super> KEY_KP5";
        slot_r = "<super> KEY_RIGHT | <super> KEY_KP6";
        slot_tl = "<super> KEY_KP7";
        slot_t = "<super> KEY_KP8";
        slot_tr = "<super> KEY_KP9";
        # Restore default.
        restore = "<super> KEY_DOWN | <super> KEY_KP0";
      };

      # Change active window with an animation.
      switcher = {
        next_view = "<alt> KEY_TAB";
        prev_view = "<alt> <shift> KEY_TAB";
      };
      # Simple active window switcher.
      fast-switcher.activate = "<alt> KEY_ESC";

      # Workspaces
      # Switch to workspace.
      vswitch = {
        binding_left = "<ctrl> <super> KEY_LEFT";
        binding_down = "<ctrl> <super> KEY_DOWN";
        binding_up = "<ctrl> <super> KEY_UP";
        binding_right = "<ctrl> <super> KEY_RIGHT";
        # Move the focused window with the same key-bindings, but add Shift.
        with_win_left = "<ctrl> <super> <shift> KEY_LEFT";
        with_win_down = "<ctrl> <super> <shift> KEY_DOWN";
        with_win_up = "<ctrl> <super> <shift> KEY_UP";
        with_win_right = "<ctrl> <super> <shift> KEY_RIGHT";
      };

      # Show the current workspace row as a cube.
      cube.activate = "<ctrl> <alt> BTN_LEFT";
      # Switch to the next or previous workspace.
      #rotate_left = <super> <ctrl> KEY_H
      #rotate_right = <super> <ctrl> KEY_L

      # Show an overview of all workspaces.
      expo = {
        toggle = "<super>";
        # Select a workspace.
        # Workspaces are arranged into a grid of 3 × 3.
        # The numbering is left to right, line by line.
        #
        # ⇱ k ⇲
        # h ⏎ l
        # ⇱ j ⇲
        # ‾   ‾
        # See core.vwidth and core.vheight for configuring the grid.
        select_workspace_1 = "KEY_1";
        select_workspace_2 = "KEY_2";
        select_workspace_3 = "KEY_3";
        select_workspace_4 = "KEY_4";
        select_workspace_5 = "KEY_5";
        select_workspace_6 = "KEY_6";
        select_workspace_7 = "KEY_7";
        select_workspace_8 = "KEY_8";
        select_workspace_9 = "KEY_9";
      };

      # Outputs
      # Change focused output.
      oswitch = {
        # Switch to the next output.
        next_output = "<super> KEY_O";
        # Same with the window.
        next_output_with_win = "<super> <shift> KEY_O";
      };
      # Invert the colors of the whole output.
      invert.toggle = "<super> KEY_I";

      # Rules ────────────────────────────────────────────────────────────────────────

      # Example configuration:
      #
      # [window-rules]
      # maximize_alacritty = on created if app_id is "Alacritty" then maximize
      #
      # You can get the properties of your applications with the following command:
      # $ WAYLAND_DEBUG=1 alacritty 2>&1 | kak
      #
      # See Window rules for a complete reference.
      # https://github.com/WayfireWM/wayfire/wiki/Configuration#window-rules
    };
    output = "wayfire.ini";
    format = "ini";
  };
in {
  home.packages = with pkgs; [
    alacritty
    font-awesome
    nixpkgs-wayland.packages.wlr-randr
    firefox
    google-chrome
    zoom-us
  ];

  xdg.enable = true;
  xdg.configFile."wayfire.ini".source = wayfireConfig.configFile;
  xdg.configFile."wofi/config".text = "mode=drun,run";
}
