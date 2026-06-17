{ ... }:

{
  # This mirrors the known-working Roost Hetzner preset. GRUB with
  # efiInstallAsRemovable plus an EF02 BIOS boot partition gives Hetzner
  # firmware both the UEFI removable path and BIOS embedding path.
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      zfsSupport = true;
    };
    efi.canTouchEfiVariables = false;
  };

  # Hetzner hardware can hang at network-online.target during boot.
  systemd.network.wait-online.enable = false;
}
