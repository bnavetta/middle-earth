# Login setup (greeter, desktop manager, etc.)
{
  config,
  lib,
  pkgs,
  ...
}: let
  /*
  # `-l` activates layer-shell mode.
  greeter = "${pkgs.greetd.wlgreet}/bin/wlgreet -l -c sway";

  # Use Sway to wrap and run the greeter
  swayConfig = pkgs.writeText "greetd-sway-config" ''
    # Notice that `swaymsg exit` will run after the greeter.
    exec "${greeter}; swaymsg exit"
    bindsym Mod4+shift+e exec swaynag \
      -t warning \
      -m 'What do you want to do?' \
      -b 'Poweroff' 'systemctl poweroff' \
      -b 'Reboot' 'systemctl reboot'

    include /etc/sway/config.d/*
  '';
  */
  swayWrapper = pkgs.writeShellScript "sway-wrapper" ''
    # Use the programs.sway wrapper
    rm -f /tmp/sway-debug.log
    sway 2>&1 | tee /tmp/sway-debug.log
  '';

  cage = pkgs.cage.overrideAttrs (final: prev: {
    # Use a debug build to enable wlroots debug logging
    mesonBuildType = "debug";
  });

  launcher = pkgs.writeShellScript "launcher" ''
    echo "OpenGL drivers:"
    ls /run/opengl-driver/lib/dri
    echo "Greeter running as: $USER"

    set -x
    export LIBGL_DEBUG=verbose
    export WLR_RENDERER_ALLOW_SOFTWARE=1
    # TODO: only really want this set for greeter
    export MESA_SHADER_CACHE_DIR="/tmp/mesa-shader-cache"
    export WLR_NO_HARDWARE_CURSORS=1 # TODO: this should only apply to VMs?
    ${cage}/bin/cage -s -- ${pkgs.greetd.gtkgreet}/bin/gtkgreet
    echo "cage exited ($?), starting shell"
    ${pkgs.zsh}/bin/zsh
  '';
in {
  environment.systemPackages = [pkgs.wayland-utils pkgs.mesa pkgs.weston];

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
        command = "${launcher}";
      };
    };
  };

  environment.etc."greetd/environments".text = ''
    ${swayWrapper}
    ${pkgs.zsh}/bin/zsh
    ${pkgs.bash}/bin/bash
  '';

  # Silence warnings from LIBGL_DEBUG=verbose about a missing /etc/drirc config file
  environment.etc."drirc".text = ''<driconf></driconf>'';
}
