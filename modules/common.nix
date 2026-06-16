{
  config,
  lib,
  pkgs,
  self,
  ...
}:

{
  system.stateVersion = "25.11";
  system.configurationRevision = self.rev or null;

  networking = {
    domain = "2140.dev";
    hostId = builtins.substring 0 8 (
      builtins.hashString "sha256" "${config.networking.hostName}.${config.networking.domain}"
    );
    useDHCP = lib.mkDefault true;

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  time.timeZone = "UTC";

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs.devNodes = "/dev/disk/by-id";
    zfs.forceImportRoot = false;
  };

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  users.mutableUsers = false;
  users.users.josie = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMIJBrWzivjlz+2BOflTlQGJ0hDOMLnwoeAJWZlgJAo ironworks-hydra"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = [
    pkgs.git
    pkgs.htop
    pkgs.jq
    pkgs.ncdu
    pkgs.ripgrep
    pkgs.tmux
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    substituters = [ "https://2140-dev.cachix.org" ];
    trusted-public-keys = [
      "2140-dev.cachix.org-1:0brdoxVmXjL5udKuI+vXXwdEjPInGQKjCiyJLReZBt8="
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  services.journald.extraConfig = ''
    SystemMaxUse=4G
    RuntimeMaxUse=1G
  '';
}
