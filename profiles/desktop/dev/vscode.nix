{pkgs, ...}: let
  marketplaceExtensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "latex-utilities";
      publisher = "tecosaur";
      version = "0.4.9";
      sha256 = "sha256-QCC690iT0Zls0ks7A66QiURO8yRZ4no4e4Bxfg6Fwpo=";
    }
    {
      name = "vscode-yaml";
      publisher = "redhat";
      version = "1.11.0";
      sha256 = "sha256-v0war8sHqnIslcI2Uvz+7JVx58cv9Xla+/gH/tIXxFQ=";
    }
    {
      name = "vscode-pets";
      publisher = "tonybaloney";
      version = "1.21.0";
      sha256 = "sha256-qdzc2PDNfINseoqF7N+AnOEvZWMeCGhtGCL93A991PU=";
    }
    {
      name = "nix-ide";
      publisher = "jnoortheen";
      version = "0.2.1";
      sha256 = "sha256-yC4ybThMFA2ncGhp8BYD7IrwYiDU3226hewsRvJYKy4=";
    }
  ];
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
