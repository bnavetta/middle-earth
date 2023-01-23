{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [
      "8.8.8.8"
    ];
    defaultGateway = "159.223.128.1";
    defaultGateway6 = "2604:a880:400:d0::1";
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "159.223.132.38"; prefixLength = 20; }
          { address = "10.10.0.5"; prefixLength = 16; }
        ];
        ipv6.addresses = [
          { address = "2604:a880:400:d0::1763:e001"; prefixLength = 64; }
          { address = "fe80::c077:99ff:feb5:31fc"; prefixLength = 64; }
        ];
        ipv4.routes = [{ address = "159.223.128.1"; prefixLength = 32; }];
        ipv6.routes = [{ address = "2604:a880:400:d0::1"; prefixLength = 128; }];
      };

    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="c2:77:99:b5:31:fc", NAME="eth0"
    ATTR{address}=="2e:02:ca:63:db:3a", NAME="eth1"
  '';
}
