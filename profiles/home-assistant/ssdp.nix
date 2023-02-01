{pkgs, ...}: {
  # Allow SSDP (the service discovery protocol used by UPnP, particularly for WeMo devices)
  # See https://discourse.nixos.org/t/ssdp-firewall-support/17809 and https://serverfault.com/a/911286/9166
  networking.firewall.extraPackages = [pkgs.ipset];
  networking.firewall.extraCommands = ''
    if ! ipset --quiet list upnp; then
      # Create a new ipset to store UPnP SSDP connections
      ipset create upnp hash:ip,port timeout 4
    fi
    # Match outgoing SSDP packets (sent to 239.255.250:1900 multicast address) and store the source IP address
    # and port into the upnp ipset
    # Unfortunately, this rule is recreated every time the firewall restarts (see https://github.com/NixOS/nixpkgs/issues/161328)
    iptables -A OUTPUT -d 239.255.255.250/32 -p udp -m udp --dport 1900 -j SET --add-set upnp src,src --exist
    # Match and accept incoming UDP packets sent to an address and port in the upnp ipset
    # These packets are responses to SSDP requests sent by UPnP clients on the host
    iptables -A nixos-fw -p udp -m set --match-set upnp dst,dst -j nixos-fw-accept
  '';
}
