# LinuxOnAndroid

[English](README.md) | 中文

在已 root 的 Android 设备上，用宿主内核运行一个 Linux rootfs。它使用私有 mount namespace、`pivot_root`、全新的 `/proc` `/sys` `/dev`、可选的 bind 设备节点，并默认把 rootfs 放在 loop 挂载的 ext4 镜像中，同时共享宿主网络命名空间。

## 解决什么问题

- 提供真实的 Linux 根文件系统，而不是 `proot` 的假象；`df` 这类感知挂载的工具能正确看到容器根。
- 在不改 Android 和内核的前提下，运行普通发行版工具与服务，例如 SSH、Tailscale、Samba、Podman、Python。
- 通过 ext4 loop 镜像承载 rootfs，避免 Android FBE/fscrypt 导致有状态服务出现 `ENOKEY`。
- 为 Alpine/Debian guest 补上 Android paranoid networking 所需的 Android gid。
- 默认只 bind `tun`、`fuse` 等通用节点，避免机型专属硬件依赖。

## 要求

- 已 root 的 Android（Magisk），以及一个由用户自己选择的可写目录（例如 `/data` 下任意位置）；脚本会从自身路径推导 `CTDIR`，不固定存放位置。
- 内核支持 mount namespace、UTS namespace、`TMPFS`；默认 loop rootfs 还需要 `BLK_DEV_LOOP` 和 `EXT4_FS`。`TUN`/`FUSE` 可选。
- SELinux 策略允许 root shell 执行 `unshare`、bind mount、`losetup`、`pivot_root`。
- rootfs 需匹配手机架构，并提供 `/bin/sh` 与基础工具（`mount`、`umount`、`mknod`、`ln`、`env`）。Alpine 和 Debian 由 `lib/guest-init-*` 处理。
- 进程可见性隔离需要 guest 内有 `capsh`（Alpine 为 `libcap-utils`，Debian 为 `libcap2-bin`）；guest 初始化会在有网络时尝试安装。

## 使用

```sh
./init.sh
./start.sh
./enter.sh
./stop.sh
```

可选开机自启：`./setup_magisk_module.sh` 会为当前目录安装一个可被 Magisk 管理的模块；`./setup_magisk_module.sh remove` 标记重启后移除，`disable`/`enable` 可开关。移动目录后需重跑。

`ROOTFS_URL=... ./init.sh` 会在 `rootfs/bin/sh` 缺失时下载并解压 rootfs 归档。`start.sh` 不依赖固定安装路径，可从任意当前目录启动；`CTDIR` 由脚本路径推导。启动时会同步 DNS；运行中网络变化后可重跑 `scripts/dns-sync.sh`。

loop rootfs 默认值：

```sh
ROOTFS_URL=... LOOP_SIZE=80G ROOTFS_BACKUP=0 ./init.sh
ROOTFS_IMG= ./init.sh          # 关闭 loop 镜像，直接使用 rootfs/ 目录
ROOTFS_LOOP_DETACH=1 ./stop.sh # stop 时同时 detach loop 设备
```

- `ROOTFS_IMG` 默认是 `$CTDIR/rootfs.img`；`LOOP_SIZE` 默认 `40G`。
- 如果已存在 `rootfs/` 但还没有 `rootfs.img`，`init.sh` 会把它迁移进新的 ext4 镜像。旧目录默认移动为 `rootfs.bak.<时间戳>`；`ROOTFS_BACKUP=0` 会直接删除。
- 默认 `stop.sh` 只卸载 rootfs，保留 loop attach，方便下次快速启动。

## 说明

- Android paranoid networking 需要 guest 内存在对应 Android gid。guest 初始化脚本会创建 `aid_inet=3003`、`aid_net_raw=3004` 并把 `root` 加入。
- `enter.sh` 和容器启动都使用干净环境（`env -i`，只带 `PATH`、`HOME=/root`、`TMPDIR=/tmp`），不继承 adb/Android 变量。
- 有 `capsh` 时，容器初始化和 `enter.sh` 会在补完 Android gid 后丢弃 `CAP_SYS_PTRACE`。配合 `hidepid=2,gid=3009` 可隐藏大部分宿主进程，但这不是 PID namespace，也不是安全边界。
- `pivot_root` 后会尽量把旧 Android 根从容器 mount namespace 分离，避免 `df` 被 `/.oldroot` 条目污染。
- 默认只 bind 通用设备节点：`/dev/tun`、存在时的 `/dev/net/tun`，以及 `/dev/fuse`。GPU/相机/音频节点默认不包含。
- `scripts/start-fore.sh` 受 `CT_FORE=1` 保护；直接运行可能破坏当前 mount namespace。
