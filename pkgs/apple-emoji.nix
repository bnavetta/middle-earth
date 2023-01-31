# Based on https://github.com/berberman/flakes/blob/master/packages/apple-emoji/default.nix
{
  stdenv,
  lib,
  sources,
}:
stdenv.mkDerivation rec {
  inherit (sources.apple-emoji) pname version src;

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    install -D -m644 $src $out/share/fonts/truetype/AppleColorEmoji.ttf
  '';

  meta = with lib; {
    homepage = "https://github.com/samuelngs/apple-emoji-linux";
    description = "Apple Color Emoji for Linux";
    license = licenses.asl20;
  };
}
