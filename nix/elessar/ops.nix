{
  inputs,
  cell,
}: let
  inherit (inputs.cells) installer;
  inherit (cell) nixos;

  inst = installer.lib.mkInstaller nixos.elessar;
in {
  # TODO: figure out how to auto-add these to all nixos system blocks?
  installer = inst;
  flash = installer.lib.mkFlash "flash-elessar-installer" inst;
}
