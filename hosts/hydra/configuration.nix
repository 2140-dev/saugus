{ ... }:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "saugus-hydra";

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
