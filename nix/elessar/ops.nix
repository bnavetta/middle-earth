{
  inputs,
  cell,
}: let
  inherit (inputs.cells) installer;
  inherit (cell) nixos;

  inst = installer.lib.mkInstaller nixos.elessar;
in {
  installer = inst;
  flash = installer.lib.mkFlash "flash-elessar-installer" inst;
}
