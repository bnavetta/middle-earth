# Middle Earth vNext

This is an experimental rewrite of some of my personal infrastructure configuration. I'm porting things to NixOS, and using Terraform for cloud configuration.

The bootstrapping is based on [this blog post from Xe Iaso](https://xeiaso.net/blog/nix-flakes-terraform).

All devices are named after characters from Lord of the Rings:

- luthien - a small VPS on DigitalOcean. Mostly just runs Nginx to proxy for Home Assistant and a few static websites
- faramir - a Raspberry Pi running Home Assistant

They're all connected via Tailscale (setup isn't quite as automated as it could be, but probably good enough), and assume that it's accessible early on
for provisioning.

Each devices updates itself from Github daily, and the flake dependencies are updated weekly by a [Github Action](.github/workflows//update-flake-lock.yml).

## Prerequisites

This requires Nix with Flakes support. To deploy to a Raspberry Pi, cross-compilation for aarch64 is also required. Follow the instructions on the
[wiki](https://nixos.wiki/wiki/NixOS_on_ARM#Compiling_through_binfmt_QEMU) to set up QEMU for building.

An [age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey) identity is configured according to https://github.com/ryantm/agenix/issues/115

## TODOs

- Automatic updates using Colmena and a GitHub app
- Restic backups
