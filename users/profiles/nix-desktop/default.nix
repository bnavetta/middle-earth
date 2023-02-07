/*
* My Linux desktop settings
*/
{
  pkgs,
  inputs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (pkgs) mustacheTemplate;
  waylandPkgs = inputs.nixpkgs-wayland.packages.${pkgs.system};
in
  lib.mkIf isLinux {
    home.packages = [
      pkgs.font-awesome
      pkgs.picom
      waylandPkgs.wlr-randr
    ];

    # https://wayland.emersion.fr/mako/ - a Wayland notification daemon
    programs.mako.enable = true;

    xdg.enable = true;
    xdg.configFile."wayfire.ini" = {
      source = mustacheTemplate "wayfire.ini" ./wayfire.ini.mustache {
        programs = {
          inherit (waylandPkgs) grim kanshi mako slurp swayidle swaylock wlogout wofi;
        };
      };
    };
  }
