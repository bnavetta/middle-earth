/*
Configures git to use bpb with an age-encrypted secret for commit signing, instead of GPG
*/
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.programs.bpb;

  bpbSecret = pkgs.writeShellApplication {
    name = "bpb-secret";
    text = ''
      age --decrypt --identity ${config.programs.age.identitiesFile} -o - <<EOS
      ${cfg.secret}
      EOS
    '';
    runtimeInputs = with pkgs; [age age-plugin-yubikey];
  };
in {
  options = {
    programs.bpb = {
      enable = mkEnableOption "bpb for git commit signing";

      userid = mkOption {
        type = types.str;
        default = "";
        description = "bpb user ID string";
      };
      key = mkOption {
        type = types.str;
        default = "";
        description = ''bpb public key'';
      };
      timestamp = mkOption {
        type = types.str;
        default = "";
        description = "bpb key timestamp";
      };
      secret = mkOption {
        type = types.str;
        description = "age-encrypted bpb secret key";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.age.enable = true;

    home.packages = [
      pkgs.bpb
    ];

    programs.git.extraConfig = {
      gpg.program = "bpb";
      commit.gpgSign = true;
      tag.forceSignAnnotated = true;
    };

    home.file.".bpb_keys.toml".text = ''
      [public]
      key = "${cfg.key}"
      userid = "${cfg.userid}"
      timestamp = ${cfg.timestamp}

      [secret]
      program = "${bpbSecret}/bin/bpb-secret"
    '';
  };
}
