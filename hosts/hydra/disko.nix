{
  disko.devices = {
    disk = {
      system0 = {
        type = "disk";
        device = "/dev/disk/by-id/REPLACE-WITH-1_92TB-NVME-0";
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
        device = "/dev/disk/by-id/REPLACE-WITH-1_92TB-NVME-1";
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

      store0 = {
        type = "disk";
        device = "/dev/disk/by-id/REPLACE-WITH-3_84TB-NVME-0";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "storepool";
            };
          };
        };
      };

      store1 = {
        type = "disk";
        device = "/dev/disk/by-id/REPLACE-WITH-3_84TB-NVME-1";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "storepool";
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

      storepool = {
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
          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "legacy";
          };
          "build" = {
            type = "zfs_fs";
            mountpoint = "/build";
            options.mountpoint = "legacy";
          };
          "hydra-cache" = {
            type = "zfs_fs";
            mountpoint = "/var/cache/hydra";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}
