# Bootstrap Files

Files only used when bootstrapping a new system via Terraform.

To bootstrap a non-Terraform system:

1. Install NixOS on the host system.
2. Set up Tailscale by configuring the system with `services.tailscale.enable = true;` and pre-authenticating with an [auth key](https://tailscale.com/kb/1085/auth-keys/).
   This configuration _should_ stick around after the host is managed.
3. Create the `./hosts/$server` directory tree:
   * `default.nix` - host configuration, see existing examples
   * `hardware-configuration.nix` and `networking.nix`, if generated when installing NixOS
   * `public-ip` - text file with the host's IP address (must be accessible to the deploy machine)
   * `ssh_pubkey` - text file with the host's SSH key, from `/etc/ssh/ssh_host_ed25519_key.pub`
4. Commit all changes
5. Deploy to the system by running `just deploy $server`

Terraform-managed systems use [nixos-infect](https://github.com/elitak/nixos-infect) to bootstrap a base NixOS configuration with Tailscale enabled. The Tailscale Terraform provider
generates their initial Tailscale auth key, and the `assimilate.sh` script configures the `./hosts/$server` directory.