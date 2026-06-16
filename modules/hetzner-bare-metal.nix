{ ... }:

{
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      zfsSupport = true;
    };
    efi.canTouchEfiVariables = false;
  };

  systemd.network.wait-online.enable = false;
}
