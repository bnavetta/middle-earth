/*
* Profile for desktop machines that I actively do things on
*/
{pkgs, ...}: {
  imports = [./dev/vscode.nix ./audio.nix ./login.nix];

  # YubiKey setup
  services.yubikey-agent.enable = true;
  services.pcscd.enable = true;
  services.udev.packages = [pkgs.yubikey-personalization];

  # services.picom.enable = true;

  environment.systemPackages = with pkgs; [
    alacritty
    discord
    dropbox
    google-chrome
    vlc
    yubikey-agent
    yubikey-manager
    zoom-us
  ];

  programs.firefox.enable = true;
  programs._1password-gui.enable = true;

  # bluetooth conky googledrive rofi
}
