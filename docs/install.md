# Install

Saugus installs onto the Hetzner Hydra host from Rescue using
`nixos-anywhere`.
This is destructive: `disko` will repartition the disks named in
`hosts/hydra/disko.nix`.

Current host inventory:

```text
IPv4: 167.235.5.73
CPU: AMD EPYC 9454P, 48 cores / 96 threads
RAM: 251 GiB
Disk: 2 x 1.92 TB NVMe, mirrored ZFS rpool
Boot: UEFI
```

## 1. Boot Rescue

Boot the server into Hetzner Rescue with the Ironworks Hydra SSH key attached,
then verify root SSH:

```sh
ssh root@<server-ip>
```

## 2. Identify Disks

Record the stable NVMe identifiers:

```sh
ssh root@<server-ip> '
  lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE
  find /dev/disk/by-id -maxdepth 1 -type l -name "nvme-*" -printf "%f -> %l\n" | sort
'
```

Expected hardware:

```text
2 x 1.92 TB NVMe
```

Update `hosts/hydra/disko.nix`:

```text
nvme-Micron_7450_MTFDKCC1T9TFR_2314406EE2C7
nvme-SOLIDIGM_SSDPF2KX019T1M_BTAX609304MQ1P9BGN
```

## 3. Install

From this repo:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake .#hydra \
  root@<server-ip>
```

## 4. First Login

After reboot:

```sh
ssh josie@<server-ip>
nixos-version --configuration-revision
zpool status
systemctl status hydra-init hydra-evaluator hydra-queue-runner
```

## 5. Subsequent Switches

```sh
nixos-rebuild switch \
  --flake .#hydra \
  --target-host josie@<server-ip> \
  --use-remote-sudo
```
