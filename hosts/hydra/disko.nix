{
  disko.devices = {
    disk = {
      system0 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Micron_7450_MTFDKCC1T9TFR_2314406EE2C7";
        content = {
          type = "gpt";
          partitions = {
            bios = {
              size = "1M";
              type = "EF02";
            };
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };

      system1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SOLIDIGM_SSDPF2KX019T1M_BTAX609304MQ1P9BGN";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };

    };

    zpool = {
      rpool = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = {
          compression = "zstd";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
          mountpoint = "none";
          canmount = "off";
        };
        options = {
          ashift = "12";
          autotrim = "on";
        };
        datasets = {
          "local" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          };
          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "legacy";
          };
          "local/build" = {
            type = "zfs_fs";
            mountpoint = "/build";
            options.mountpoint = "legacy";
          };
          "local/hydra-cache" = {
            type = "zfs_fs";
            mountpoint = "/var/cache/hydra";
            options.mountpoint = "legacy";
          };

          "safe" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          };
          "safe/var" = {
            type = "zfs_fs";
            mountpoint = "/var";
            options.mountpoint = "legacy";
          };
          "safe/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };
          "safe/postgresql" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/postgresql";
            options = {
              mountpoint = "legacy";
              recordsize = "16K";
            };
          };
          "safe/hydra" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/hydra";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}
