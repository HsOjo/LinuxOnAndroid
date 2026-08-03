# LinuxOnAndroid

English | [中文](README.zh.md)

Run a Linux rootfs on a rooted Android device with the host kernel. It uses a private mount namespace, `pivot_root`, fresh `/proc` `/sys` `/dev`, optional bind-mounted device nodes, and by default a loop-mounted ext4 rootfs image while sharing the host network namespace.

## What it solves

- Provides a real Linux root filesystem instead of a `proot` illusion, so mount-aware tools such as `df` see the container root correctly.
- Runs normal distro tools and services such as SSH, Tailscale, Samba, Podman, or Python while keeping Android and the kernel unchanged.
- Avoids Android FBE/fscrypt `ENOKEY` failures for stateful services by putting the rootfs on an ext4 loop image.
- Patches Alpine/Debian guests with the Android group IDs needed for Android paranoid networking.
- Avoids model-specific hardware dependencies by binding only generic nodes such as `tun` and `fuse`.

## Requirements

- Rooted Android with Magisk and a writable directory chosen by the user (for example under `/data`); the scripts derive `CTDIR` from their own path.
- Kernel with mount and UTS namespaces, `TMPFS`; for the default loop rootfs also `BLK_DEV_LOOP` and `EXT4_FS`. `TUN`/`FUSE` are optional.
- SELinux policy that allows the root shell to `unshare`, bind-mount, `losetup`, and `pivot_root`.
- A rootfs matching the phone architecture with `/bin/sh` and basic tools (`mount`, `umount`, `mknod`, `ln`, `env`). Alpine and Debian are handled by `lib/guest-init-*`.

## Usage

```sh
./init.sh
./start.sh
./enter.sh
./stop.sh
./backup.sh
./restore.sh
```

Optional boot autostart: `./setup_magisk_module.sh` installs a manageable Magisk module for the current directory; `./setup_magisk_module.sh remove` schedules removal, and `disable`/`enable` toggles it. Re-run after moving the directory. If SELinux blocks the loop rootfs (kernel write denials on `rootfs.img`), `./init.sh` applies `setenforce 0` best-effort and `./setup_selinux_magisk_module.sh` installs a Magisk module that repeats it at boot; it supports the same `remove`/`disable`/`enable` subcommands.

`ROOTFS_URL=... ./init.sh` downloads and extracts a rootfs archive when `rootfs/bin/sh` is missing. `start.sh` can be run from any current directory; `CTDIR` is derived from the script path. DNS is synced at start and kept in sync by a host-side watchdog that polls every `DNS_SYNC_INTERVAL` seconds (default `30`; `0` disables it).

Loop rootfs defaults:

```sh
ROOTFS_URL=... LOOP_SIZE=80G ROOTFS_BACKUP=0 ./init.sh
ROOTFS_IMG= ./init.sh          # disable the loop image and use rootfs/ directly
ROOTFS_SPARSE=1 ./init.sh      # create the image as a sparse file (default off)
ROOTFS_LOOP_DETACH=1 ./stop.sh # also detach the loop device at stop
```

- `ROOTFS_IMG` defaults to `$CTDIR/rootfs.img`; `LOOP_SIZE` defaults to `40G`.
- If `rootfs/` already exists and `rootfs.img` is missing, `init.sh` migrates it into a new ext4 image. The old directory is moved to `rootfs.bak.<timestamp>` unless `ROOTFS_BACKUP=0`, which deletes it.
- By default `stop.sh` unmounts the rootfs but keeps the loop device attached for a fast next start.

Backup and restore:

- `backup.sh` packs the rootfs (mounted image or plain directory) into `$BACKUP_DIR/rootfs.<timestamp>.tar.gz` via a streaming `tar | gzip` pipe. It works while the container is running, mounts the image temporarily when needed, and keeps the newest `ROOTFS_BACKUP_KEEP` archives (default `2`; `BACKUP_DIR` defaults to `$CTDIR/backup`).
- `restore.sh [archive]` restores the newest archive (or the given one): the container must be stopped; it wipes the rootfs and extracts the archive.

Diagnostics:

- Runtime stages are logged to `run/container.log`; the log is truncated to the newest half once it exceeds `LOG_MAX_KB` KiB (default `256`).

## Notes

- Android paranoid networking needs Android group IDs in the guest. The guest init scripts create `aid_inet=3003` and `aid_net_raw=3004` and add `root` to them.
- `enter.sh` and container boot start with a clean environment (`env -i` with `PATH`, `HOME=/root`, `TMPDIR=/tmp`) instead of inheriting adb/Android variables.
- The guest is not privilege-isolated: guest root keeps the full capability set and shares the pid/network namespaces with the host, so it can see and affect host processes. This is a convenience container, not a security boundary.
- After `pivot_root`, the old Android root is detached from the container mount namespace when possible, so `df` is not polluted by `/.oldroot` entries.
- Only generic device nodes are bound by default: `/dev/tun`, `/dev/net/tun` when present, and `/dev/fuse`. GPU/camera/audio nodes are intentionally not included.
- `scripts/start-fore.sh` is guarded by `CT_FORE=1`; running it directly can break the current mount namespace.
