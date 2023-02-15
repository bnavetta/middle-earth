{pkgs, ...}: {
  services.yubikey-agent.enable = true;
  services.pcscd.enable = true;
  services.udev.packages = [pkgs.yubikey-personalization];

  environment.systemPackages = [pkgs.yubikey-manager pkgs.yubikey-agent];
}
