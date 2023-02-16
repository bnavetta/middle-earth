{
  inputs,
  cell,
}: let
  inherit (inputs) nixpkgs;
  inherit (cell) nixago;

  lib = nixpkgs.lib // builtins;
in {
  default = {...}: {
    nixago = [
      nixago.agenix
    ];

    packages = [
      nixpkgs.age
      nixpkgs.age-plugin-yubikey
    ];

    commands = [
      {
        package = nixpkgs.age;
        category = "Ops";
      }
      {
        name = "agepasswd";
        category = "Ops";
        help = "Generate a Linux password hash secret";
        command = ''
          if [[ $# -ne 1 ]]; then
            echo >&2 "Usage: agepasswd <path-to-secret>"
            exit 1
          fi
          ${lib.getExe nixpkgs.mkpasswd} -m yescrypt | agenix --editor - --edit "$1"
        '';
      }
      {
        name = "age-rekey";
        category = "Ops";
        help = "Re-key all agenix secrets";
        command = "agenix --rekey --identity ./nix/ben/age-identities.txt";
      }
      {
        name = "age-host-identity";
        category = "Ops";
        help = "Generate a new age host identity";
        command = ''
          if [[ $# -ne 1 ]]; then
            echo >&2 "Usage: age-host-identity <host name>"
            exit 1
          fi

          target_host="$1"
          mkdir -p "./nix/$target_host/secrets"

          WORKDIR="$(mktemp -d)"
          trap "rm -rf $WORKDIR" EXIT

          ${nixpkgs.age}/bin/age-keygen -o "$WORKDIR/identity.txt"
          ${nixpkgs.age}/bin/age-keygen -y "$WORKDIR/identity.txt" > "$WORKDIR/recipient.txt"

          age --encrypt -R "./nix/ben/age-recipients.txt" -o "./nix/$target_host/secrets/identity.age" < "$WORKDIR/identity.txt"
        '';
      }
    ];
  };
}
