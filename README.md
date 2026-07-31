# LinuxOnAndroid

English | [中文](README.zh.md)

Run a Linux rootfs on a rooted Android device with the host kernel. It uses a private mount namespace, `pivot_root`, fresh `/proc` `/sys` `/dev`, and optional bind-mounted device nodes while sharing the host network namespace.

## What it solves

- Provides a real Linux root filesystem instead of a `proot` illusion, so mount-aware tools such as `df` see the container root correctly.
- Runs normal distro tools and services such as SSH, Tailscale, Samba, or Python while keeping Android and the kernel unchanged.
- Patches Alpine/Debian guests with the Android group IDs needed for Android paranoid networking.
- Avoids model-specific hardware dependencies by binding only generic nodes such as `tun` and `fuse`.

## Requirements

- Rooted Android with Magisk and a writable directory chosen by the user (for example under `/data`); the scripts derive `CTDIR` from their own path.
- Kernel with mount and UTS namespaces, `TMPFS`; `TUN`/`FUSE` are optional.
- SELinux policy that allows the root shell to `unshare`, bind-mount, and `pivot_root`.
- A rootfs matching the phone architecture with `/bin/sh` and basic tools (`mount`, `umount`, `mknod`, `ln`). Alpine and Debian are handled by `lib/guest-init-*`.

## Usage

```sh
./init.sh
./start.sh
./enter.sh
./stop.sh
```

Optional boot autostart: `./setup_magisk_module.sh` installs a manageable Magisk module for the current directory; `./setup_magisk_module.sh remove` schedules removal, and `disable`/`enable` toggles it. Re-run after moving the directory.

`ROOTFS_URL=... ./init.sh` downloads and extracts a rootfs archive when `rootfs/bin/sh` is missing. `start.sh` can be run from any current directory; `CTDIR` is derived from the script path. DNS is synced at start; while running, rerun `scripts/dns-sync.sh` after network changes.

## Notes

- Android paranoid networking needs Android group IDs in the guest. The guest init scripts create `aid_inet=3003`, `aid_net_raw=3004`, and `aid_readproc=3009`, then add `root` to them.
- Only generic device nodes are bound by default: `/dev/tun`, `/dev/net/tun` when present, and `/dev/fuse`. GPU/camera/audio nodes are intentionally not included.
- `scripts/start-fore.sh` is guarded by `CT_FORE=1`; running it directly can break the current mount namespace.
