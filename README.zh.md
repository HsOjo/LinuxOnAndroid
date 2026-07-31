# LinuxOnAndroid

[English](README.md) | 中文

在已 root 的 Android 设备上，用宿主内核运行一个 Linux rootfs。它使用私有 mount namespace、`pivot_root`、全新的 `/proc` `/sys` `/dev`，以及可选的 bind 设备节点，同时共享宿主网络命名空间。

## 解决什么问题

- 提供真实的 Linux 根文件系统，而不是 `proot` 的假象；`df` 这类感知挂载的工具能正确看到容器根。
- 在不改 Android 和内核的前提下，运行普通发行版工具与服务，例如 SSH、Tailscale、Samba、Python。
- 为 Alpine/Debian guest 补上 Android paranoid networking 所需的 Android gid。
- 默认只 bind `tun`、`fuse` 等通用节点，避免机型专属硬件依赖。

## 要求

- 已 root 的 Android（Magisk），以及一个由用户自己选择的可写目录（例如 `/data` 下任意位置）；脚本会从自身路径推导 `CTDIR`，不固定存放位置。
- 内核支持 mount namespace、UTS namespace、`TMPFS`；`TUN`/`FUSE` 可选。
- SELinux 策略允许 root shell 执行 `unshare`、bind mount、`pivot_root`。
- rootfs 需匹配手机架构，并提供 `/bin/sh` 与基础工具（`mount`、`umount`、`mknod`、`ln`）。Alpine 和 Debian 由 `lib/guest-init-*` 处理。

## 使用

```sh
./init.sh
./start.sh
./enter.sh
./stop.sh
```

可选开机自启：`./setup_magisk_module.sh` 会为当前目录安装一个可被 Magisk 管理的模块；`./setup_magisk_module.sh remove` 标记重启后移除，`disable`/`enable` 可开关。移动目录后需重跑。

`ROOTFS_URL=... ./init.sh` 会在 `rootfs/bin/sh` 缺失时下载并解压 rootfs 归档。`start.sh` 不依赖固定安装路径，可从任意当前目录启动；`CTDIR` 由脚本路径推导。启动时会同步 DNS；运行中网络变化后可重跑 `scripts/dns-sync.sh`。

## 说明

- Android paranoid networking 需要 guest 内存在对应 Android gid。guest 初始化脚本会创建 `aid_inet=3003`、`aid_net_raw=3004`、`aid_readproc=3009`，并把 `root` 加入这些组。
- 默认只 bind 通用设备节点：`/dev/tun`、存在时的 `/dev/net/tun`，以及 `/dev/fuse`。GPU/相机/音频节点默认不包含。
- `scripts/start-fore.sh` 受 `CT_FORE=1` 保护；直接运行可能破坏当前 mount namespace。
