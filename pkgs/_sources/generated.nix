# This file was generated by nvfetcher, please do not modify it manually.
{
  fetchgit,
  fetchurl,
  fetchFromGitHub,
  dockerTools,
}: {
  apple-emoji = {
    pname = "apple-emoji";
    version = "ios-15.4";
    src = fetchurl {
      url = "https://github.com/samuelngs/apple-emoji-linux/releases/download/ios-15.4/AppleColorEmoji.ttf";
      sha256 = "sha256-CDmtLCzlytCZyMBDoMrdvs3ScHkMipuiXoNfc6bfimw=";
    };
  };
}
