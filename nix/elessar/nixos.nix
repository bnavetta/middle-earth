{
  inputs,
  cell,
}: {
  elessar = inputs.cells.lib.lib.mkSystem {
    name = "elessar";
    system = "x86_64-linux";
    modules = [
      {
        system.stateVersion = "23.05";

        # TODO: should be able to auto-configure this per host
        # TODO: https://discourse.nixos.org/t/impermanence-a-file-already-exists-at-etc-machine-id/20267/5
        # machine-id is theoretically confidential?
        environment.etc.machine-id.text = "0b8a8daa064f43d49c14ad709903ef43";
        networking.hostId = "0b8a8daa";

        fileSystems."/efi" = {
          device = "/dev/nvme0n1p2";
          fsType = "vfat";
          neededForBoot = true;
        };
      }
      inputs.cells.base.profiles.default
    ];

    meta.description = "NixOS desktop";
  };
}
