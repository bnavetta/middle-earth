{
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs) vscode-utils;

  sources = pkgs.callPackage ./vscode/_sources/generated.nix {};
  mkExtension = source:
    vscode-utils.buildVscodeMarketplaceExtension {
      vsix = source.src;
      mktplcRef = {
        name = source.pname;
        inherit (source) version publisher;
      };
    };

  # Build every extension managed by nvfetcher (have to filter out non-package entries from pkgs.callPackage)
  marketplaceExtensions = map mkExtension (lib.filter (s: s ? pname) (lib.attrValues sources));

  packagedExtensions = with pkgs.vscode-extensions; [
    matklad.rust-analyzer
    james-yu.latex-workshop
    ms-python.vscode-pylance
    ms-vscode-remote.remote-ssh
    hashicorp.terraform
    skellock.just
  ];

  vscode =
    pkgs.vscode-with-extensions.override
    {
      vscodeExtensions = marketplaceExtensions ++ packagedExtensions;
    };
in {
  environment.systemPackages = [
    vscode
  ];
}
