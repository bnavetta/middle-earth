agenix_identity := "secrets/identities/age-yubikey-identity-880f0c54.txt"

# Format all applicable source files
fmt:
    nix fmt

# Validate the Nix configuration
check:
    nix flake check

# Deploy configuration
deploy target='all':
    deploy "{{ if target == 'all' { '.' } else { '.#' + target } }}"

# Build a DigitalOcean image for Luthien
build-do-image:
    nix build .#packages.x86_64-linux.luthien-image
    @echo "Image built to result/nixos.qcow2.gz"

# Re-encrypt all age secrets to match the recipients specified in ./secrets.nix
rekey:
    agenix --identity "{{ agenix_identity }}" -r

# Edit the age-encrypted secret `secret`
edit-secret secret:
    agenix --identity "{{ agenix_identity }}" -e "{{ secret }}"

# Update all flake inputs and commit the new flake.lock file
update-flake:
    nix flake update --commit-lock-file --commit-lockfile-summary "Update flake.lock"