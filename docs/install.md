# Install

Saugus installs onto the Hetzner AX162-R from Rescue using `nixos-anywhere`.
This is destructive: `disko` will repartition the disks named in
`hosts/hydra/disko.nix`.

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
2 x 1.92 TB NVMe Datacenter
2 x 3.84 TB NVMe Datacenter
```

Update `hosts/hydra/disko.nix`:

```text
REPLACE-WITH-1_92TB-NVME-0
REPLACE-WITH-1_92TB-NVME-1
REPLACE-WITH-3_84TB-NVME-0
REPLACE-WITH-3_84TB-NVME-1
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
