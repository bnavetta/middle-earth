# Secret management

Secrets are encrypted with [agenix](https://github.com/ryantm/agenix). The `secrets.nix` file is itself auto-generated from cell configurations.

## TODO: bootstrapping

use yubikey recipient to age-encrypt each host's identity, then installer decrypts that and copies into persistent location
* should store yubikey stuff under ben cell since it's mine, encrypted identities in cell for each host
* installer library function can resolve those as needed
* make sure installer ISO has age-plugin-yubikey set up