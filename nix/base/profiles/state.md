Ephemeral-by-default storage, AKA [impermanence](https://github.com/nix-community/impermanence),
[Erase Your Darlings](https://grahamc.com/blog/erase-your-darlings),
or [tmpfs as root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/).

This configures the system so that:

- `/` is a `tmpfs`
- `/nix` is on the `rpool/local/nix` ZFS dataset
- `/home` is on the `rpool/safe/home` ZFS dataset
- Persistent, reproducible data is on the `rpool/local/persist` ZFS dataset, mounted at `/persist/local`
- Persistent, backed-up data is on the `rpool/safe/persist` ZFS dataset, mounted at `/persist/safe`
- State is linked to `/persist` as needed

**WARNING** Backups for `rpool/safe` datasets aren't actually implemented yet
