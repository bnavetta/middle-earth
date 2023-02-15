{
  inputs,
  cell,
}: let
  inherit (inputs.cells) installer;
  inherit (cell) nixos;
in {
  installer = installer.lib.mkInstaller nixos.elessar;
}
