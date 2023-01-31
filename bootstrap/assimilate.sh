#!/usr/bin/env bash
set -e

# Assimilate a new host by setting up its NixOS config

USAGE() {
    echo "Usage: $(basename $0) <server_name> <public_ip>" >&2
    exit 2
}

if [[ -z $1 || -z $2 ]]; then
    USAGE
fi

server_name="${1}"
public_ip="${2}"

# SSH to a host, ignoring its host key
ssh_ignore() {
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $*
}

# SSH into the victim host identified by the caller
ssh_victim() {
    ssh_ignore "root@$public_ip" $*
}

scp_victim() {
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "root@$server_name:$1" "$2"
}

# Set up the config tree for the victim
mkdir -p "./hosts/$server_name"
echo "$public_ip" >"./hosts/$server_name/public-ip"

# Not using ssh_victim because we want Tailscale SSH
until ssh_ignore "root@$server_name" uname -av; do sleep 30; done

# Copy over the host's auto-detected hardware config and SSH key
scp_victim "/etc/nixos/hardware-configuration.nix" "./hosts/$server_name" || :
scp_victim "/etc/nixos/networking.nix" "./hosts/$server_name" || :
scp_victim "/etc/ssh/ssh_host_ed25519_key.pub" "./hosts/$server_name/ssh_pubkey" || :

# Write out a host-specific NixOS module
# The root flake configuration will combine this with shared setup
rm -f "./hosts/$server_name/default.nix"
cat <<-EOC >"./hosts/$server_name/default.nix"
{ ... }: {
    stateVersion = "23.05";
}
EOC

nix fmt "hosts/$server_name"
git add "hosts/$server_name"
git commit -sm "add machine $server_name"

# Must commit _before_ building, since the git revision is built into the system configuration
# nix build ".#nixosConfigurations.${server_name}.config.system.build.toplevel"

# Initialize the system by copying over the built configuration
export NIX_SSHOPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
deploy ".#${server_name}"
# nix-copy-closure -s "root@$public_ip" "$(readlink ./result)"
# ssh_victim nix-env --profile /nix/var/nix/profiles/system --set "$(readlink ./result)"
# ssh_victim "$(readlink ./result)/bin/switch-to-configuration" switch

git push
