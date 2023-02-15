# Support for working with iOS devices
{pkgs, ...}: {
  services.usbmuxd.enable = true;

  environment.systemPackages = with pkgs; [
    libimobiledevice
    ifuse
  ];
}
