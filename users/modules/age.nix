/*
* Baseline configuration for using age
*/
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.programs.age;
in {
  options = {
    programs.age = {
      enable = mkEnableOption "age";

      identitiesFile = mkOption {
        type = types.path;
        description = ''
          File listing age identities belonging to the user.
          This may contain secret keys directly, or if using age-plugin-yubikey
          identities, it does not need to be secret.
        '';
      };

      recipientsFile = mkOption {
        type = types.path;
        description = ''          '
                    File listing age recipients belonging to the user.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      age-plugin-yubikey

      # writeShellScriptBin
      # "age-view"
      # ''
      #   age --decrypt --identity ${cfg.identitiesFile} -o - $@
      # ''
    ];
  };
}
