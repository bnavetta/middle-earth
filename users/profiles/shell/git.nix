/*
Git configuration:
- commit signing via bpb
- delta for diffs
*/
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) importTOML;
  userDir = ../../users/${config.home.username};
  bpbConfig = importTOML (userDir + /bpb.toml);
in {
  programs.age = {
    enable = true;
    identitiesFile = userDir + /age-identities.txt;
    recipientsFile = userDir + /age-recipients.txt;
  };

  programs.bpb = {
    enable = true;
    userid = bpbConfig.public.userid;
    key = bpbConfig.public.key;
    timestamp = bpbConfig.public.timestamp;
    secret = bpbConfig.secret.encryptedKey;
  };

  programs.git = {
    enable = true;

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
}
