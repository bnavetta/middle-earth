{pkgs, ...}: let
  tex = pkgs.texlive.combine {
    # See https://nixos.wiki/wiki/TexLive and https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/tools/typesetting/tex/texlive/pkgs.nix
    inherit (pkgs.texlive) scheme-medium collection-bibtexextra collection-fontsextra collection-humanities collection-latexextra;
  };
in {
  imports = [./vscode.nix];

  environment.systemPackages = [tex pkgs.qemu pkgs.strace];

  security.polkit.enable = true;
  virtualisation.libvirtd.enable = true;
}
