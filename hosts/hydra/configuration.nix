{ ... }:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "saugus-hydra";
    useDHCP = false;
    nameservers = [
      "185.12.64.1"
      "185.12.64.2"
      "2a01:4ff:ff00::add:1"
      "2a01:4ff:ff00::add:2"
    ];
  };

  systemd.network = {
    enable = true;
    networks."10-uplink" = {
      matchConfig.Name = "en* eth*";
      networkConfig = {
        Gateway = [
          "167.235.5.1"
          "fe80::1"
        ];
        IPv6AcceptRA = false;
      };
      addresses = [
        {
          Address = "167.235.5.73/32";
          Peer = "167.235.5.1/32";
        }
        {
          Address = "2a01:4f8:2b01:b15::2/64";
        }
      ];
    };
  };

  services.ironworks.hydraController = {
    enable = true;
    hostName = "hydra.2140.dev";
    notificationSender = "hydra@2140.dev";
    useACME = false;
    minimumDiskFree = 300;
    minimumDiskFreeEvaluator = 100;
  };

  nix.settings = {
    max-jobs = 48;
    cores = 2;
    build-dir = "/build";
    min-free = 300 * 1024 * 1024 * 1024;
    max-free = 800 * 1024 * 1024 * 1024;
  };
}
