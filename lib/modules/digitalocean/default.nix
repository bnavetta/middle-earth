# NixOS module to configure DigitalOcean agents
{ config, pkgs, lib, ... }:
{
  services.do-agent.enable = true;
}
