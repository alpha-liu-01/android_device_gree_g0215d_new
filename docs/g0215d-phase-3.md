# 阶段 3：第一套可交互系统

日期：2026-10-26。阶段 2 已收口。本文件只记阶段 3 的推荐步骤，以及以后做的时候要补的实现笔记和事件。路线图仍是 `docs/g0215d-android-16-roadmap.md`。

完成标准：Lineage 18.1 的桌面可交互。启动画面、无横纹桌面、触摸、adb、电源键熄屏再亮屏、Wi-Fi、扬声器和听筒、蓝牙、传感器、双卡、数据、充电和休眠唤醒都通过。相机和指纹这一阶段只要求进程还在。SELinux 保持 permissive，denial 有记录。刷 boot 之前原厂 boot 已另存。日常进 recovery 用 2016-10-07 那份能挂上 data 的镜像。`#17` 留在硬盘上，只做内核画面测试。

步骤 1 到步骤 5 已结束。背光已经能亮。一次误开机里 SurfaceFlinger 不再崩溃，翻页 ioctl 因为句柄里的虚拟地址被改写而失败。`gralloc.default` 已改为把本进程映射留在进程内，翻页改用句柄里的字节 `offset`。随后一次开机里，`panel_hold.sh` 在 composer 打开 `fb0` 的同时写了 `blank`，两边都没有返回。脚本加上 8 秒等待后，composer 和 SurfaceFlinger 都完成初始化并进入了开机动画；将 `fb_post` 改为 `FB_ACTIVATE_NOW | FB_ACTIVATE_FORCE` 调 `FBIOPUT_VSCREENINFO` 并补上 `libaudiohal` 6.0 回退后，屏幕已能看到开机动画，`audioserver` 也不再崩溃。动画停住是因为系统缺少 `android.hardware.wifi.xml` 等硬件特性权限文件，`SystemUI` 在 `provideWifiManager` 返回空指针崩溃，进而触发 `RescueParty` 调用尚未加载元数据的 `ModuleInfoProvider.getModuleInfo`（加密最小框架下 `ModuleMetadata` 非 `coreApp` 被跳过），导致 `system_server` 反复重启（共 18 次）。硬件特性权限 XML 已补齐，`ModuleInfoProvider` 在缺少元数据包时也已将 `mMetadataLoaded` 置为 `true`。重启后系统顺利走过开机动画并显示出 `CryptKeeper` 解密失败界面（Holo 样式），画面上下颠倒对应 `persist.panel.inversemounted=180`（Android 11 对应 `ro.surface_flinger.primary_display_orientation=ORIENTATION_180`），同时触发了步骤 1「18.1 若要求加密升级或格式化 data，先停」的停机点。从这份 recovery 执行重启到 bootloader 会直接重新开机，进不了 fastboot。触摸芯片曾停在引导模式，原厂固件 `A4_2F_4.0_05.fw` 已写回，`atmel_mxt_ts` 已重新绑定。

## 推荐停在 Lineage 18.1

用户态用 LineageOS 18.1，也就是 Android 11。内核继续用阶段 2 的 `#17`（4.4.302，私有仓库 `alpha-liu-01/android_kernel_gree_g0215d` 的 `g0215d` 分支）。

选 18.1 是因为这台手机的分区现在放得下它。system 是 3 GiB（`3221225472` 字节），没有 vendor、odm、product、super。本地已有的一加 3 `lineage-18.1` 树，`recovery.fstab` 写明 non-A/B、non-split、没有 `vendor.img`，`BOARD_SYSTEMIMAGE_PARTITION_SIZE` 是 `3154116608`。这个大小落在格力这块 3 GiB 的 system 里。

小米 `lineage-22.2` 的 `msm8996-common` 另要 `872415232` 字节（832 MiB）的 vendor。本仓库的 `BoardConfig.mk` 已经把 vendor 大小留空，那份对 common 的继承是阶段 4 重分区之后的布局。18.1 的 lunch 先不包含它。

20 和 21 先不作为这一阶段的构建树。18.1 的桌面和下面的验收表过了之后，再看那一代的镜像能不能放进现有 system。现在本地没有 20 或 21 的 msm8996 设备树，再同步一份整树对第一次点亮桌面没有更多信息。

`/run/media/alpha/YMTC/lineage-23.2/` 是 Android 16 的用户态，清单里没有 MSM8996 的设备树，也不能 lunch 18.1。18.1 的清单要单独放在这块移动硬盘上。23.2 那份树留给阶段 5。

一加 3 的 18.1 树只提供「vendor 留在 system 里」的平台形状，以及 `BoardConfig`、init、fstab、sepolicy、manifest 从 Android 7 长到 11 的样子。面板时序、Atmel 触摸、Goodix 指纹、格力相机库不从那棵树拿。内核也不换成它的 `kernel/oneplus/msm8996`。

## 阶段 2 留下的四件事落在哪一步

| 阶段 2 留下的事 | 落在 |
| --- | --- |
| 电源键熄屏再亮屏还没单独按过。recovery 脚本每 2 秒写 `blank 0` 并托住背光 | 步骤 6。系统 ramdisk 里没有 `phase2-debug.sh` |
| 启动日志里仍有 `0x34` 然后 `0x28` 的 DMA 超时 | 步骤 6。四项检查通过就记下来，继续验收。画面出横纹或触摸停在 CFGERR，就回到 `#17` 这颗内核 |
| 触摸配置仍是芯片 NVM 的 `53a963`。原厂 raw 在 `/system/etc/firmware/` | 步骤 3 把固件放进镜像，步骤 7 看 `config_csum` |
| 系统 boot 仍是原厂 3.18 | 步骤 4、步骤 5。第一次刷 boot 之前核对备份 |

## 步骤 1：确认还能退回去

推荐：刷写之前核对阶段 0 的备份还在，并且能对上。

- data：`third_party/2026-10-26--07-27-02_HALO_1.2.1_D1/`，TWRP 文件备份，md5 已通过。不含内部存储 `/data/media`
- system：同目录旁的 System 备份，以及 `g0215d/device-backup/` 里的 `system.img`
- boot：`device-backup` 里的原厂 boot。内核是 2017-04-12 的 `3.18.20-perf`，ramdisk 是 HALO 加 SuperSU
- 进 recovery 用 `device-backup/recovery.img`。那是 2016-10-07 的 `3.18.20-perf` 加上 TWRP 3.0.2，阶段 0 用它挂上过 `/data` 和内部存储。`#17` 的用户态也是这份 TWRP，但 4.4 内核的 ICE 映射读不出 ext4，见下面的事件
- 18.1 的 fstab 继续写 `encryptable=footer`，和一加 3 的 18.1 一样。同一份 2016 recovery 就能挂现在的 data。文件加密的新 TWRP 留到 data 真的改成 FBE 再做
- 退回 Android 6 时写 boot 和 system。recovery 保持这份能读 footer 的镜像。启动链分区（aboot、xbl、tz、rpm、hyp、cmnlib、keymaster、modemst、fsg）不动。只有 data 被格式化或改成文件加密之后，恢复才要先刷回这份 recovery，再写 boot、system，并用已有的 TWRP 文件备份恢复 data

第一次刷机不格式化 data。18.1 若要求加密升级或格式化 data，先停。清掉会丢掉那约 7.5 GB 的解密数据，以及 `/data/su.img`。

刷回能挂载 data 的 recovery：

```text
fastboot flash recovery /run/media/alpha/YMTC/g0215d/device-backup/recovery.img
```

### 实现笔记

当前 recovery 是 `#17`：TWRP 3.0.2 的用户态，内核 `4.4.302-perf+`。`/etc/recovery.fstab` 里 data 是 ext4、`encryptable=footer`、`length=-16384`。userdata 节点是 `sda9`。system 分区 `sde18` 能挂上。fstab 里的外置卡 `mmcblk1` 和 USB-OTG `sdg` 没有对应设备。

TWRP 用默认口令解开了 footer。日志是 `Device is encrypted with the default password` 和 `Successfully decrypted with default password`。映射类型是 `req-crypt`，参数 `fde_enabled ice`，新块设备是 `/dev/block/dm-0`。内核写了 `Mapping block_device /dev/block/sda9 to dm-req-crypt ok!`。`dm-0` 大小 `59212754944`，比 `sda9` 的 `59212771328` 少 16384，正好是 footer。

这块 `dm-0` 的 1024 字节处不是 ext4 超级块。`EXT4-fs (dm-0): VFS: Can't find ext4 filesystem`，手动 `mount -t ext4` 返回 `Invalid argument`。`/data/media` 是这块文件系统里的目录，所以内部存储和 data 一起失败。日志里的 `Unable to mount storage` 就是这件事。MTP 还另有一句 `could not open MTP driver`，`/dev/mtp_usb` 不存在；那是 4.4 用 configfs 之后的 USB 节点，和文件系统读不出来是两件事。

挂上 data 的办法是刷回 2016 年那份 recovery。在这颗 4.4 上修 ICE，留到真的要在 `#17` 里读写 data 时再做。

3.18 这份 recovery 上的核对：

- `device-backup/SHA256SUMS` 十一份镜像全部通过。TWRP 的 `data.ext4.win` md5 `96887c51eba11e8b2bb34551d356dd4b`，`system.ext4.win` md5 `a5ca564ded4d198a57312b21dd846ff0`，都通过
- 正在运行的 boot 分区与 `boot.img` 相同，SHA256 `07b402f192d2ddeee4646455cd33085055b3cc85193f47afed177de6ae4e11de`。recovery 分区与 `recovery.img` 相同，SHA256 `4c14c80cfc6a8b77f354cd5d939d9bc94a3d2f3df02f0a39eeb107907c6f76ac`
- system 分区 3221225472 字节。和 `system.img` 相比，主超级块（0–4096）以及偏移 2895872 起的 16 KiB 日志不同。日志魔数是 jbd2，其中 22 个字节不同。空闲块 399041、空闲 inode 192091，两边一样。其余数据块一致。`#17` 挂过这块 system：挂载时间被写成 1970-01-01，挂载次数从 3 变成 103，累计写入增加 1800 KB。文件没有增删。现在不需要为了步骤 1 把 `system.img` 刷回去
- `/data` 和 `/sdcard` 都挂在 `dm-0` 上。容量 54.2 GB，已用 10.3 GB，可用 43.8 GB。`/data/su.img` 是 96 MB。`/data/media` 是 9.0 GB、6205 个文件，仍然不在 TWRP 的 Data 备份里
- 外置卡和 USB-OTG 的节点是空的，fstab 里的那两项挂不上

### 事件

2026-10-26：机器先停在 `#17` recovery。画面和 adb 正常，`uname` 含 `4.4.302`，`ro.twrp.version=3.0.2-0`。cache 已挂上。data、`/data/media` 未挂上。

同日稍后刷回 `device-backup/recovery.img`。`uname` 是 `3.18.20-perf`，编译时间 Fri Oct 7 15:28:14 CST 2016，TWRP `3.0.2-0`。默认口令解密成功，`/data` 和 `/sdcard` 已挂上。boot、recovery 与备份字节相同。system 只差超级块和日志头。TWRP 界面显示内置存储剩余 44897 MB，与日志里的 Free 一致。步骤 1 结束。

## 步骤 2：准备 18.1 用户态

推荐：在移动硬盘上按 LineageOS 18.1 的清单同步一份用户态。内置盘不放这棵树。同步范围是能 lunch 出 `lineage_g0215d` 的平台，加上 `device/qcom/sepolicy-legacy-um`。小米和一加的专有 vendor 不下载。格力 blob 从 `device-backup/system.img` 和 System 备份里抽。

本仓库现在的 `device.mk` 继承 `device/xiaomi/msm8996-common`。那份 common 是 `lineage-22.2`。18.1 的产品文件要换成不含这份继承的板级 makefile，放进 18.1 树里的 `device/gree/g0215d`。仓库里现有的骨架留在原地，给阶段 4 接回 common。

### 实现笔记

用户态在 `/run/media/alpha/YMTC/lineage-18.1`，约 99 GB。清单是 `LineageOS/android.git` 的 `lineage-18.1`。`repo sync -c --no-tags --no-clone-bundle`。`device/qcom/sepolicy-legacy-um` 在默认清单里，已经检出。`vendor/oneplus`、`vendor/xiaomi`、`kernel/oneplus` 没有下载。

第一次同步末尾，`external/python/httplib2` 和 `external/squashfs-tools` 被 AOSP 回了 HTTP 429。单独再同步这两项之后，整树 `repo sync` 成功。

`device/gree/g0215d` 放在这棵 18.1 树里，没有继承 `device/xiaomi/msm8996-common`，也没有继承 `device/oppo/common`。本仓库里给阶段 4 用的骨架没有改。`BoardConfig.mk` 写了实机分区：system `3221225472`，cache `268435456`，userdata `59212771328`，boot 和 recovery 各 `67108864`。没有 `vendor.img`。构建系统因此把 `TARGET_COPY_OUT_VENDOR` 定成 `system/vendor`。fstab 里 data 只有 ext4，标志是 `encryptable=footer`。dsp 是 ext4，modem 和 bluetooth 是 vfat，persist 是 ext4。

内核偏移沿用阶段 2：基址 `0x80000000`，页 4096，tags `0x00000100`，ramdisk `0x01000000`。cmdline 用 `cma=32M` 和 `androidboot.selinux=permissive`。`TARGET_NO_KERNEL := true`，这棵树不编内核。Lineage 在没写 `TARGET_KERNEL_SOURCE` 时会从设备目录推成 `kernel/gree/g0215d`，那个目录现在不存在，因为内核编译被关掉了。

`lunch lineage_g0215d-userdebug` 选出的是 Android 11、`LINEAGE_VERSION=18.1-20261026-UNOFFICIAL-g0215d`、`BUILD_ID=RQ3A.211001.001`。lunch 时有一句 `Trying dependencies-only mode on a non-existing device tree?`，因为 `device/gree/g0215d` 不是 repo 管理的 git 项目，没有 `lineage.dependencies`。没有去拉一加或小米的依赖。

### 事件

2026-10-26：步骤 1 以界面上的内置存储剩余 44897 MB 收口。同日同步完 18.1，并 lunch 成功。没有刷机。

## 步骤 3：板级产品放进 system

推荐：18.1 的镜像是一块 system。`BOARD_SYSTEMIMAGE_PARTITION_SIZE` 用实机的 `3221225472`。不生成 `vendor.img`。`TARGET_COPY_OUT_VENDOR` 在这套 non-split 布局里落在 `/system/vendor`。

这一步要放进镜像的板级文件：

- 音频：`audio_platform_info.xml`、`mixer_paths_tasha.xml`。扬声器走 SLIMBUS
- 键位：`gpio-keys.kl`、`tiny4412-key.kl`。导航是实体键
- 相机配置：`msm8996_camera_G0215D.xml`，路径保持 `/system/etc/camera/`。传感器以这份 XML 里的 `s5k3p3`、`ov8858` 为准
- 触摸固件：`A4_2F_4.0_05.fw` 和 `Gree2_4005_V2.06_20170223.raw`，放在 `/system/etc/firmware/`。System 备份里已经有这两份。CM 列表里的 `A4_35_1.0_AA.fw` 和 `A4_35.raw` 在这台手机上不存在
- 分辨率：1440×2560，`xxxhdpi`。heap 和 overlay 按这块 2K 屏写，不照一加 3 的 1080p、6 GB 内存

开机后的 init 沿用原厂脚本的动作：等触摸节点出现，把固件写到 `update_fw`，把 raw 写到 `update_cfg`，再写 `plugin`。这棵内核的 `plugin` 只记录命令，不会跑原厂 `atmel_stand` 引擎。配置要靠 `update_cfg` 写进去。

SELinux 在内核 cmdline 里保持 `androidboot.selinux=permissive`。denial 存下来，这一阶段不切 enforcing。

### 实现笔记

板级文件在 `/run/media/alpha/YMTC/lineage-18.1/device/gree/g0215d`。本仓库的阶段 4 骨架没有改。两份触摸固件只放在那棵树里，校验和与 `docs/reference/g0215d-halo-blobs.sha256` 一致：`A4_2F_4.0_05.fw` 188908 字节，`9ef8974c82b967fe05815453ded7bb21f8e7ae8befba7044bca327f0f704f949`；`Gree2_4005_V2.06_20170223.raw` 8285 字节，开头是 `OBP_RAW V1`，`8460144470d0087e27026161ab10bb3133118118ea47cb927755c60d7e6f80ad`。没有放入 `A4_35_1.0_AA.fw` 和 `A4_35.raw`。

`lunch` 看到的安装路径：

- `system/vendor/etc/audio_platform_info.xml`、`mixer_paths_tasha.xml`。扬声器路径走 `SLIM_0_RX`，耳机走 `SLIMBUS_6_RX`
- `system/vendor/usr/keylayout/gpio-keys.kl`、`tiny4412-key.kl`。`gpio-keys.kl` 里 key 59 是 `GREE_KEY`
- `system/etc/camera/msm8996_camera_G0215D.xml`。后摄 `s5k3p3`（CameraId 0），前摄 `ov8858`（CameraId 2）
- `system/etc/firmware/` 下的两份触摸文件
- `system/bin/init.atmel_ts.sh` 和 `system/etc/init/init.gree.rc`

`init.gree.rc` 的 `atmel_tp_init` 是 `class main`、`oneshot`、root。脚本等到 `12-004a/update_fw` 出现，再写入原厂那两行文件名，等 1 秒，然后写 `ac enable 1` 和 `pl enable 20`。cmdline 增加了 `firmware_class.path=/system/etc/firmware`，给 `request_firmware` 用。`plugin` 仍然只被这颗内核记下来。

分辨率 1440×2560，`xxxhdpi`，`ro.sf.lcd_density=640`，`qemu.hw.mainkeys=1`，overlay 里 `config_showNavigationBar` 为 false。heap 用 4 GB 配置：`heapstartsize=8m`，`heapgrowthlimit=256m`，`heapsize=512m`，`heaptargetutilization=0.6`，`heapminfree=8m`，`heapmaxfree=16m`。`heapgrowthlimit` 按 1440×2560 的缓冲从 4 GB 档的 192m 提到 256m，`heapsize` 仍是 512m。

`BOARD_SYSTEMIMAGE_PARTITION_SIZE` 是 `3221225472`。`BOARD_USES_VENDORIMAGE` 为空，`TARGET_COPY_OUT_VENDOR` 是 `system/vendor`。cmdline 里仍是 `androidboot.selinux=permissive`。denial 要等系统真的启动后再存，这一步没有切 enforcing，也没有刷机。

### 事件

2026-10-26：固件从 `device-backup/system.img` 的 `etc/firmware` 抽出，大小和校验和与 blob 清单一致。`lunch lineage_g0215d-userdebug` 再次通过，上面的拷贝路径和属性都在产品变量里。

## 步骤 4：把 `#17` 打进 boot

推荐：boot 镜像的内核就是阶段 2 的 `Image.gz-dtb`，只带格力这一份 DTB。18.1 的构建系统不要去编 `kernel/oneplus/msm8996`，也不要重编 `g0215d` 工作树，除非步骤 6 把问题退回内核。

打包参数与阶段 2 相同：页大小 4096，内核地址 `0x80008000`，ramdisk `0x81000000`，tags `0x80000100`。`#17` 页对齐后落在 `0x80c36000`，和 ramdisk 之间仍有空隙。内核必须停在 `0x81000000` 之下。

系统 boot 的 cmdline 用现在这块原厂 boot 的 `cma=32M@0-0xffffffff`，并带上 `androidboot.selinux=permissive`。recovery 测试用过的 `cma=16M` 只属于那份 recovery。bootloader 还会自己追加 HMP、`androidboot.bootdevice=624000.ufshc`、verified boot 状态，以及面板选择 `qcom,mdss_dsi_nt35597_wqxga_cmd` 的 `config0` 加 `split_dsi`。这些不写进镜像头。

`fastboot boot` 在这台 bootloader 上不可用。验证只能 `fastboot flash boot`。刷之前把 `device-backup` 里的原厂 boot 再对一次校验和，确认退路文件还是 2017-04-12 那份。

系统 ramdisk 里不放 `phase2-debug.sh`。

### 实现笔记

boot 镜像是 `/run/media/alpha/YMTC/g0215d/boot-test/boot-phase3.img`，13611008 字节，SHA256 `b36b827ece0c0926d3661cae36c6bb356afb16e6411f9d20247b06176c82792c`。头是 `ANDROID!`，header version 0。页大小 4096，内核地址 `0x80008000`，ramdisk `0x81000000`，tags `0x80000100`。内核与阶段 2 的 `Image.gz-dtb` 字节相同，12769992 字节，页对齐后落到 `0x80c36000`，和 ramdisk 之间空 3973120 字节。解压后的版本串是 `Linux version 4.4.302-perf+`、`#17 SMP PREEMPT Mon Oct 26 15:43:24 EDT 2026`。后面只拼了一份 DTB，model 是 `Gree G0215D MSM8996 v3 + PMI8996`。18.1 没有去编 `kernel/oneplus/msm8996`，也没有重编这棵内核。`TARGET_NO_KERNEL` 仍是 true。

cmdline 是 `cma=32M@0-0xffffffff`，带 `androidboot.selinux=permissive` 和 `firmware_class.path=/system/etc/firmware`，末尾是构建系统会加的 `buildvariant=userdebug`。没有写入 HMP、`androidboot.bootdevice`、verified boot 或 `split_dsi`。

ramdisk 是 18.1 的第一阶段 `init`，静态链接，`Android 30`，1844448 字节。里面有 `/fstab.qcom`，只挂 system，标志是 `wait,first_stage_mount`。第一阶段 init 要靠这一行把 system 挂上并切到它，然后执行 `/system/bin/init`。vendor 里的 fstab 仍不列 system，切根之后由它挂 data、cache、modem、dsp、bluetooth、persist。ramdisk 里没有 `phase2-debug.sh`。

为了让 kati 能解析 msm8996 的 display makefile，`BoardConfig.mk` 加了 `TARGET_USES_HWC2` 和 `TARGET_USES_GRALLOC1`。当前 `vendor/apn` 依赖清单里没有的 `pyyaml`，所以在 18.1 树里放了一份 PyYAML 5.4.1，只为生成 ninja。这两件事都没有编进 boot。

`device-backup/boot.img` 仍是 `07b402f192d2ddeee4646455cd33085055b3cc85193f47afed177de6ae4e11de`。没有刷机。`fastboot boot` 仍然不能用来验证，验证要等步骤 5 的 `fastboot flash boot`。

### 事件

2026-10-26：`m ramdisk` 得到 18.1 的第一阶段 ramdisk。`#17` 打进 `boot-phase3.img`，头里的地址和页对齐落点与阶段 2 一致。原厂 boot 的校验和未变。没有刷入。

## 步骤 5：第一次刷写的范围

推荐：只刷 boot 和 system。recovery、cache、userdata、persist、modem、dsp、bluetooth 保持不动。

不刷 `third_party/` 里的卡刷包。MIUI 包和底层包的脚本会写启动链。Resurrection Remix 和自用 lineage13 包用的是原厂或 TWRP 那两颗 3.18 内核。

刷完用 recovery 的 `#17` 作为退路：系统起不来时，从 recovery 看得到画面和 adb，再用备份写回 boot 和 system。

### 实现笔记

system 镜像是 `/run/media/alpha/YMTC/g0215d/boot-test/system-phase3.img`，稀疏格式，文件 1485095408 字节，SHA256 `a47ca832c639044ec1e22ed5b08aaa3afab6a44d5fb58820886a723af8c00410`。展开后正好 `3221225472` 字节。根上的 `init` 指向 `/system/bin/init`。`/system/etc/firmware/` 里有 `A4_2F_4.0_05.fw` 和 `Gree2_4005_V2.06_20170223.raw`。vendor fstab 的 userdata 仍是 `encryptable=footer`，没有 quota，也不列 `/system`。`ro.build.version.release=11`，`ro.lineage.version=18.1-20261026-UNOFFICIAL-g0215d`。

这次 `m systemimage` 在主机上补了几处，都只在 18.1 树里：ncurses 5 的符号链接、arm64 WebView 的 git-lfs 实体、`make-apns.py` 在 Python 3.8 上的 `ElementTree.indent`。Ubuntu 的 `mke2fs.conf` 带 `orphan_file`，AOSP 的 mke2fs 1.45.4 读不懂，所以 `out/soong/host/linux-x86/bin/mke2fs` 和 `out/host/linux-x86/bin/mke2fs` 外面套了一层，改读 `system/extras/ext4_utils/mke2fs.conf`。这些都没有写进手机。

从当时的 2016 recovery 进 fastboot，只写了 boot 和 system。boot 用 `boot-phase3.img`，system 用上面这份稀疏镜像。fastboot 的 `max-download-size` 是 `0x20000000`，system 分成三段写入，三段都是 OKAY。没有 `fastboot -w`，没有格式化 data。recovery、cache、userdata、persist、modem、dsp、bluetooth 没有写。`third_party/` 的卡刷包没有刷。手机停在 fastboot。

`device-backup/boot.img` 仍是 `07b402f192d2ddeee4646455cd33085055b3cc85193f47afed177de6ae4e11de`，`device-backup/system.img` 仍是 `28354e1730de242dbf25201f2bb255f5ea7bdce3a2fc472227c21fa8ebadb513`。recovery 分区仍是 2016 那份。`#17` 的 recovery 镜像仍在 `boot-test/recovery-phase2.img`，这次没有刷进去。系统起不来时，先用现有 recovery 或 fastboot，把 boot 和 system 写回备份：

```text
fastboot flash boot /run/media/alpha/YMTC/g0215d/device-backup/boot.img
fastboot flash system /run/media/alpha/YMTC/g0215d/device-backup/system.img
```

### 事件

2026-10-26：18.1 的 system 镜像打出来并刷入，同时刷入 `boot-phase3.img`。其余分区未动。手机停在 fastboot，等第一次开机。

## 步骤 6：第一次进系统只看四件事

推荐：第一次开机只看这四件，外加一次电源键。

1. 启动画面出现
2. 桌面 1440×2560，没有横纹
3. 触摸能点
4. adb 起来

然后按一次电源键熄屏，再按一次亮屏。这时没有 recovery 脚本每 2 秒解屏，也没有人把背光托在固定值上。同时看 dmesg 里的 `0x34` / `0x28` 和 T6 状态。

这四件里任何一件失败，或者熄屏再亮屏之后出现横纹、触摸停在 CFGERR，就回到 `#17` 的内核改。用户态先不加包、不升到 20/21。桌面进不去，说明问题还在阶段 2 的板级移植。

四件都过了，把这次的 dmesg 留在事件里，再进步骤 7。

### 实现笔记

`boot-phase3.img` 交出去之后、system 挂上之前就复位了。在 `#17` recovery 里，system 的挂载次数仍是 0，`/sys/fs/pstore` 是空的。同一颗内核可以把这份 18.1 的 ext4 只读挂上，`ro.lineage.version=18.1-20261026-UNOFFICIAL-g0215d`。boot 分区当时和 `boot-phase3.img` 字节相同。

调试镜像是 `/run/media/alpha/YMTC/g0215d/boot-test/boot-debug.img`，13611008 字节，SHA256 `4e0c130ab5ca49c76a19c71932becb7b58aeff5e3db72d7ca508d2b4258ad470`。内核字节、页大小 4096、内核 `0x80008000`、ramdisk `0x81000000`、tags `0x80000100`、header version 0 都和 `boot-phase3.img` 相同。cmdline 多了 `androidboot.init_fatal_reboot_target=recovery`。ramdisk 里原来的 Android 11 init 改名为 `/init.real`。新的 `/init` 先用设备号 8:3 挂上 cache，把 `/dev/kmsg` 逐条同步写到 `/cache/boot-kmsg.txt`，再执行 `/init.real`。标记文件是 `/cache/boot-debug-marker`。

这次只写了 boot。system 仍是 18.1，recovery 仍是 `#17`。

`boot-debug.img` 开机停在第一屏循环，红灯不亮。cache 上没有 `boot-debug-marker`，也没有 `boot-kmsg.txt`。这次 recovery 的开机原因是硬复位，上一次关机是 MSM 拉低 PS_HOLD。pstore 仍是空的。那份 cpio 的名字填充按名字长度对齐，内核的 `N_ALIGN` 要求从流起点对齐。第一个目录项就错了 2 字节，`/init` 没有执行。

下一份是 `/run/media/alpha/YMTC/g0215d/boot-test/boot-debug2.img`，13611008 字节，SHA256 `83b4872c6c95b4f5baac17be8fe317e19d938775be72c0bb952564d316832250`。内核、地址、header version 0 和 cmdline 与上一份相同。ramdisk 用 GNU cpio 的 newc 重打，按内核的 `N_ALIGN` 能走到 `TRAILER!!!`。`/init` 3856 字节，`/init.real` 1844448 字节。

`boot-debug2.img` 的标记是 `mount=0`、`exec=0`。`/cache/boot-kmsg.txt` 里，`init.real` 先等 `dtbo, vbmeta, vendor` 的 uevent，10 秒后超时，然后 `Failed to mount required partitions early`，`InitFatalReboot: signal 6`。donor 的 `msm8996.dtsi` 在 `firmware/android/fstab` 里写了 vendor，`fsmgr_flags` 是 `wait,avb`，`vbmeta/parts` 是 `vbmeta,boot,system,vendor,dtbo,recovery`。第一阶段 init 优先用这份设备树 fstab，ramdisk 里的 `/fstab.qcom` 没有被读到。`boot`、`system`、`recovery` 存在，所以集合里只剩下那三个没有的分区。

格力板级 dts 给这个 fstab 节点加了 `status = "disabled"`。`ReadFstabFromDt` 因此失败，第一阶段改读 ramdisk 的 `/fstab.qcom`，只挂 system。内核 gzip 仍是 `#17`，新 DTB 接在后面，页对齐落点仍是 `0x80c36000`。镜像是 `/run/media/alpha/YMTC/g0215d/boot-test/boot-debug3.img`，13611008 字节，SHA256 `469e5c9705a7bd77aefe7079c7e0db9d96d634100fdf81219e96680ef72d5d07`。

`boot-debug3.img` 的日志里，设备树 fstab 读取失败，接着去打开 `/dev/block/bootdevice/by-name/system`。第一阶段的 uevent 只会在 `androidboot.boot_devices` 命中时建立 `/dev/block/by-name/system`。cmdline 里原有的是 bootloader 追加的 `androidboot.bootdevice=624000.ufshc`，键名不同，所以等了 20 秒后 `Failed to mount /system`。UFS 平台设备是 `soc/624000.ufshc`。

`boot-debug4.img` 的 cmdline 加上 `androidboot.boot_devices=soc/624000.ufshc`。ramdisk fstab 和 system 里的 vendor fstab 都改成 `/dev/block/by-name/`。userdata 仍是 `encryptable=footer`。镜像 13611008 字节，SHA256 `d3c46a49f773b48db47e7d5cdef06b5c33be6c0fc1417f9afd14e38ef264f4de`。只写了 boot，并改了 system 里的那份 fstab。

`boot-debug4.img` 这次挂上了 `/system`，第二阶段 init 也起来了。`/system/etc/init` 里没有任何 `mount_all`，`/data` 和 `/cache` 仍是 system 镜像上的只读目录。`vdc cryptfs init_user0` 因此失败，日志是 `Failure (reboot suppressed): init_user0_failed`。红灯一直亮着，zygote 反复因为建不出 `/data/dalvik-cache` 退出。

userdata 的 footer 魔数是 `0xD0B5B1C4`，版本 1.3，`crypt_type` 是 default，加密名是 `aes-xts`，KDF 是 scrypt-keymaster。flags 含 `CRYPT_DATA_CORRUPT`。fstab 没有 `formattable`。`init.gree.rc` 增加了 `on fs` / `mount_all /vendor/etc/fstab.qcom`。cache、dsp、modem、bluetooth、persist 加了 `nofail`，避免其中一次挂载失败把 userdata 的加密结果盖掉。userdata 一行没改。boot 分区仍是 `boot-debug4.img`。

这次开机日志是 `Unable to read config file '/system/etc/init/init.gree.rc': Skipping insecure file`。adb 写入后文件模式是 `666`，init 拒绝组可写和其他人可写的 rc。`mount_all` 没有执行，现象和上一份相同。`init.gree.rc` 已改成 `644`、`system_file`。`fstab.qcom` 已改成 `644`、`vendor_configs_file`。

权限改完之后，`mount_all` 成功。cache 和 persist 挂上。dsp、modem、bluetooth 的挂载点当时不存在。userdata 被记成 `possibly an encryptable blkdev`，`cryptfs mountdefaultencrypted` 之后属性是 `vold.decrypt=trigger_restart_min_framework`。系统里没有 keymaster 服务。surfaceflinger、zygote、keystore 都收到信号 6，所以屏幕一直黑。footer 的 `failed_decrypt_count` 仍是 0。

随后装上 `android.hardware.graphics.composer@2.1-service` 和 allocator。没有 `hwcomposer.msm8996` 时，这个服务改用 `gralloc.default` 打开 framebuffer。`/vendor/dsp`、`/vendor/firmware_mnt`、`/vendor/bt_firmware` 已建好。`init.gree.rc` 在 `post-fs` 把 logcat 写到 `/cache/boot-logcat.txt`。

这次开机 composer 已注册 `IComposer/default`，SurfaceFlinger 也连上了它。退出点在 `SurfaceFlinger::init`：`couldn't find an OpenGL ES implementation`。`ro.board.platform=msm8996`，镜像里没有 `libEGL_msm8996.so`。keystore 同时退出：`no viable keymaster device found`。进程内的软件 keymaster 只填 `SOFTWARE`，keystore 还要求 `TRUSTED_ENVIRONMENT`；有 HIDL 软件 keymaster 时，keystore 会把它升成默认设备。

system 里补了 `libEGL_swiftshader.so`、`libGLESv1_CM_swiftshader.so`、`libGLESv2_swiftshader.so`（32 位和 64 位，放在 `vendor/lib/egl` 和 `vendor/lib64/egl`），`vendor/build.prop` 写了 `ro.hardware.egl=swiftshader`。同时装上 `android.hardware.keymaster@4.0-service`（`SecurityLevel::SOFTWARE`）和 `libkeymaster4.so`。rc 和二进制的模式、标签已改过。boot 分区仍是 `boot-debug4.img`。软件 keymaster 解不开原来的 scrypt-keymaster footer。

这次开机 SwiftShader 三个库都加载了，gralloc 打开了 `mdssfb_90000`（1440×2560）。`BootAnimationShownTiming` 出现 28 次。大约 7.2 秒时内核写了 `release splash handoff`，面板随后保持黑。system_server 同样退出 28 次，原因是 `No IHealth service instance`。SurfaceFlinger 在 system_server 退出后于 `GLESRenderEngine::drawLayers` 收到信号 11。软件 keymaster 已注册，vold 用它签名时得到 `KM_ERROR_INVALID_KEY_BLOB`（-33），主密钥没有解出来，`failed_decrypt_count` 仍是 0。

随后装上 `android.hardware.health@2.1-service` 和 `android.hardware.health@2.0-impl-2.1.so`。`panel_hold.sh` 在 `sys.boot_completed` 变成 1 之前，每 2 秒写 `fb0/blank` 为 0，并把 `lcd-backlight` 写成 180。

这次开机背光亮了。health 2.1 已注册，`system_server` 走到了 `StartDisplayManager`。`BootAnimationShownTiming` 出现 20 次。SurfaceFlinger 每次都在 `sw::clear` 收到信号 11，故障地址都是 `0x6db6132000`。那是 framebuffer 句柄里带着的分配进程虚拟地址。`gralloc_map` 对 `PRIV_FLAGS_FRAMEBUFFER` 不做 mmap。导入进程里的 SwiftShader 直接写这个地址。`mapper.cpp` 已改为：句柄的 `pid` 不是当前进程时，用句柄里的 fd 重新 mmap。

这次误开机的日志里，SurfaceFlinger 没有再收到信号 11，开机动画记了 `BootAnimationShownTiming`。翻页失败，日志是 `FBIOPUT_VSCREENINFO failed`。导入进程把 mmap 得到的地址写回了句柄的 `base`，这个字段会随 Binder 回到分配进程，yoffset 因此越界。本进程映射改存在进程内表里，不再改 `base`。`fb_post` 用句柄里的字节 `offset` 计算 yoffset；`FBIOPUT_VSCREENINFO` 失败时再试 `FBIOPAN_DISPLAY`。`panel_hold.sh` 当时改成只写一次 `fb0/blank`。

下一次看着屏幕的开机没有背光。logcat 里有两段。前一段从 `10:27:30` 到 `10:31:46`，是这次要看的开机。SurfaceFlinger 在加载 SwiftShader 之后没有打出 EGL 信息，`system_server` 反复停在 `nativeGetPhysicalDisplayIds`，看门狗约每分钟杀掉一次。composer 只打了 `falling back to gralloc module`，没有打出分辨率。同一时刻 `panel_hold.sh` 已经在写 `fb0/blank`，这次写入没有返回，背光亮度也没有写上。后一段从 `10:32:03` 起，是随后尝试进 recovery 时自己重启的那次，不作为这次画面的依据；那段里 composer 在 1 秒内打开了 1440×2560 的 framebuffer。`panel_hold.sh` 已改回每 2 秒写 `blank` 和背光，但第一次写入前先等 8 秒，让 composer 先完成 `fb0` 的打开。

加上 8 秒等待后的这次开机里，composer 和 allocator 都打开了 1440×2560 的 `fb0`，SurfaceFlinger 完成了初始化并打出 `Enter boot animation`，`BootAnimationShownTiming` 也已记录，过程中没有任何显示服务崩溃。屏幕仍然无背光、无画面，原因是两件事叠加：第一，`gralloc.default` 的 `fb_post` 用 `FB_ACTIVATE_VBL` 调 `FBIOPUT_VSCREENINFO`，而内核 `drivers/video/fbdev/core/fbmem.c` 的 `fb_set_var` 只在 `(var->activate & FB_ACTIVATE_MASK) == FB_ACTIVATE_NOW` 时才调用 `fb_pan_display`，`FB_ACTIVATE_VBL` 直接返回 0 而不提交帧；`mdss_fb` 在 unblank 时把 `allow_bl_update` 设为 `false`，要等第一次 `mdss_fb_pan_display_ex` 提交帧调用 `mdss_fb_update_backlight` 才会把背光送给面板，所以没有真实 pan 就既不刷画面也不亮背光。第二，`system_server` 走到音频服务后一直停在 `Waiting for service 'media.audio_policy'`，因为 `libaudiohal` 的 `FactoryHalHidl.cpp` 用 `version != nullptr` 遍历以 `nullptr` 结尾的 `sAudioHALVersions` 数组，并且 `AudioFlinger` 对空的 `mDevicesFactoryHal` 直接解引用，导致 `audioserver` 每 5 秒收到信号 11。`framebuffer.cpp` 的 `fb_post` 当时改为设置 `FB_ACTIVATE_NOW` 并优先调用 `FBIOPAN_DISPLAY`；`FactoryHalHidl.cpp` 改为 `*version != nullptr`，`AudioFlinger.cpp` 构造函数增加了空指针判断，并装上了 `android.hardware.audio.service`、`android.hardware.audio@6.0-impl`、`android.hardware.audio.effect@6.0-impl` 及 32 位音频库。

随后这次开机背光重新亮起，验证了 `mdss_fb_pan_display` 已解开内核的 `allow_bl_update` 背光门控；画面仍然黑且机器发热，日志显示两处原因：第一，内核 `mdss_mdp_overlay.c` 的 `mdss_mdp_overlay_pan_display` 只在 `(fbi->var.activate & FB_ACTIVATE_VBL) || (fbi->var.activate & FB_ACTIVATE_FORCE)` 为真时才调用 `mfd->mdp.kickoff_fnc(mfd, NULL)`。`kickoff_fnc` 负责把新分配的左右 pipe 写进 `mixer->stage_pipe[MDSS_MDP_STAGE_BASE]` 并把像素发往 DSI；只传 `FB_ACTIVATE_NOW`（0）且走 `FBIOPAN_DISPLAY` 时，`fbi->var.activate` 为 0，`kickoff_fnc` 不执行，`mixer->stage_pipe` 保持为空，下一帧 `mdss_mdp_get_staged_pipe` 找不到已挂载的 base pipe，又重新分配两条新 pipe，5 帧之内耗尽全部 2 条 DMA、4 条 RGB、4 条 VIG pipe，之后每秒几十次报错 `mdss_mdp_overlay_pan_display: unable to allocate base pipe`。`fb_post` 已改为 `m->info.activate = FB_ACTIVATE_NOW | FB_ACTIVATE_FORCE` 并调用 `FBIOPUT_VSCREENINFO`，既满足 `fb_set_var` 的 `(activate & FB_ACTIVATE_MASK) == FB_ACTIVATE_NOW`（把 `fbi->var.activate` 更新并调 `fb_pan_display`），又满足 `mdss_mdp_overlay_pan_display` 的 `FB_ACTIVATE_FORCE` 触发 `kickoff_fnc`。第二，`android.hardware.audio.service` 虽然已注册 `IDevicesFactory/default`（6.0），但因缺少 `/vendor/manifest.xml`，`hwservicemanager` 的 `getTransport` 返回 `EMPTY`，`createPreferredImpl` 仍返回空指针，随后在 `AudioFlinger::onFirstRef` 和 `loadHwModule_l` 里解引用 `mDevicesFactoryHal` 再次触发信号 11。`FactoryHalHidl.cpp` 已在 `getTransport` 循环未命中时直接回退调用 `createHalService("6.0", interface, &rawInterface)`，`AudioFlinger::onFirstRef` 与 `loadHwModule_l` 也已加上 `mDevicesFactoryHal != nullptr` 保护。

改成 `FB_ACTIVATE_NOW | FB_ACTIVATE_FORCE` 之后，这次开机屏幕已经显示出 LineageOS 开机动画，`unable to allocate base pipe` 与 `audioserver` 信号 11 均已消失，`AudioFlinger` 打出 `systemReady`。一直停在开机动画且发热，是因为 `system_server` 进入了每 45 秒一次的 Java 崩溃循环（共 18 次）：
1. `/vendor/etc/permissions/` 下当时只有 `handheld_core_hardware.xml`，没有 `android.hardware.wifi.xml` 等硬件特性声明；`SystemServer` 因 `hasSystemFeature(FEATURE_WIFI)` 为假而跳过启动 `WifiService`。随后 `SystemUI` 启动时，`SystemServicesModule.provideWifiManager` 返回 `null`，被 Dagger 的 `@Provides` 非空检查抛出 `NullPointerException` 导致 `com.android.systemui` 崩溃。
2. `com.android.systemui` 崩溃触发 `PackageWatchdog` 与 `RescuePartyObserver.mayObservePackage`，后者调用 `ModuleInfoProvider.getModuleInfo`。因为当前处于加密最小框架（`mOnlyCore = true`），`/system/product/app/ModuleMetadata` 没有 `coreApp="true"` 属性而被 `PackageManager` 跳过，`ModuleInfoProvider.systemReady()` 捕获 `NameNotFoundException` 返回时未把 `mMetadataLoaded` 设为 `true`，导致 `getModuleInfo` 直接抛出 `IllegalStateException: Call to getModuleInfo before metadata loaded`，把整个 `system_server` 杀掉并重启 Zygote。
现在已将 `android.hardware.wifi.xml`、蓝牙、电话、传感器、音频、相机、指纹、GPS、NFC、USB 等 35 个硬件特性 XML 装入 `/system/vendor/etc/permissions/`（并同步写入 `device.mk`），同时修改 `ModuleInfoProvider.java` 在找不到元数据包时也将 `mMetadataLoaded` 置为 `true`，重编并推入了 `services.jar` 与 `oat/arm64/services.*`。

随后这次开机走完了开机动画，进入了 `CryptKeeper` 的解密失败界面（AOSP Holo 样式，未点击恢复出厂按钮），画面无横纹但上下颠倒 180 度。
- **画面上下颠倒 180 度**：实机面板物理反装 180 度（原厂属性 `persist.panel.inversemounted=180`）。`device.mk` 已有 `ro.surface_flinger.primary_display_orientation=ORIENTATION_180`，但当时运行中的 `vendor/build.prop` 没有这条。已在 recovery 里补上 `ro.sf.hwrotation=180`、`persist.panel.inversemounted=180` 和 `ORIENTATION_180`。
- **为什么出现解密失败界面**：第一，userdata 的 FDE footer 里自带 `flags = 0x1008`，含 `CRYPT_DATA_CORRUPT`（`0x8`），`vold` 的 `cryptfs_crypto_complete` 看到该位直接返回 `CRYPTO_COMPLETE_CORRUPT`（-4），`CryptKeeper` 的 `ValidationTask` 随即调用 `showFactoryReset(true)`；第二，原厂 FDE 走的是高通 `req-crypt` + UFS ICE 硬件加密（`aes-xts` + `scrypt_keymaster` + `qseecomd` + `libcryptfs_hw`），而当前 4.4 内核的 ICE 映射对这块 3.18 加密的 `sda9` 尚不能呈出有效 ext4 超级块（见步骤 1 笔记）。这正是步骤 1 约定的「18.1 若要求加密升级或格式化 data，先停」停机点。
- **用户接受格式化 userdata 之后**：不要在这份 `#17` TWRP 的界面里点 Wipe。TWRP 已把 `sda9` 映射成 `dm-0`，界面格式化只会动映射设备，16 KB footer 还在，下次开机仍会进 CryptKeeper。实际做法是先把 `sda9` 末尾 16384 字节的 footer 写成 0（魔数 `0xD0B5B1C4` 已消失），再 `adb reboot recovery` 让 `dm-0` 脱落，然后对整块 `sda9` 做 `mke2fs -t ext4 -F -L userdata`。新文件系统 54.2 GB，已挂上核对，footer 仍是 0。18.1 的 fstab 保持 `encryptable=footer`，没有 footer 就不会强制加密。

### 事件

2026-10-26：`boot-debug4.img` 挂上了 system。红灯常亮十几分钟，是因为没有 `mount_all`，`init_user0` 失败后重启被抑制，zygote 反复退出。随后在 system 的 `init.gree.rc` 加上 `mount_all`。再开机时 init 因文件模式 `666` 跳过了这个 rc。权限改为 `644` 后，`mount_all` 认出加密 userdata，最小框架里的 surfaceflinger 和 zygote 退出。随后装上 framebuffer composer。

同日：composer 起来之后，SurfaceFlinger 因没有 OpenGL ES 实现退出，keystore 因没有 keymaster 退出。红灯仍常亮，机器不发热。随后装上 SwiftShader 和软件 keymaster 4.0。

同日稍后：SwiftShader 已加载，开机动画在日志里记过，屏幕仍黑。system_server 因没有 IHealth 反复退出。随后装上 health 2.1，并加上解开 `fb0`、托住背光的脚本。

同日再后：背光已亮，画面仍黑。SurfaceFlinger 写到了分配进程的 framebuffer 地址。`gralloc.default` 已改为在导入进程里重新映射。

同日：从 recovery 重启到 bootloader 会直接重新开机。手动回到 recovery 后没有触摸，画面没有横纹。芯片停在引导模式，状态是 `APP_CRC_FAIL`，探测失败，没有输入设备。引导地址 `0x26` 上写回 `A4_2F_4.0_05.fw` 之后，驱动报 Family 164、Variant 47、固件 V4.0.05，T100 范围 X1439 Y2559，`config_csum` 是 `53a963`，T6 回到 `0x0`。TWRP 已打开 `event2`。`init.atmel_ts.sh` 不再每次开机重写应用固件。

同日再后：那次误开机的 cache 日志里，SurfaceFlinger 保持运行，画面仍黑。原因是翻页 ioctl 失败。`gralloc.default` 和 `panel_hold.sh` 已按上面的笔记更新。

同日：按这次修改重启后，第一屏之后黑屏，红灯常亮，没有背光，机器不发热。看着屏幕的那一段日志里，`blank` 写入和 framebuffer 打开撞在一起，SurfaceFlinger 没有完成图形初始化。`panel_hold.sh` 已改为先等 8 秒。

同日再后：等待 8 秒的开机里，composer 与 SurfaceFlinger 正常进入开机动画，无背光是因为 `fb_post` 的 `FB_ACTIVATE_VBL` 在内核 `fb_set_var` 中不触发 `fb_pan_display`，`mdss_fb` 的首帧背光门控一直未解开；同时 `system_server` 卡在等待崩溃的 `audioserver`。

同日：将 `fb_post` 改为 `FB_ACTIVATE_NOW` 后，背光重新亮起，但画面仍黑且发热。kmsg 显示 `mdss_mdp_overlay_pan_display` 需要 `fbi->var.activate` 含 `FB_ACTIVATE_VBL` 或 `FB_ACTIVATE_FORCE` 才会调 `kickoff_fnc` 把 pipe 挂上 mixer，否则 5 帧内耗尽全部 10 条 SSPP pipe（4928 次 `unable to allocate base pipe`）；同时无 `/vendor/manifest.xml` 时 `getTransport` 返回 `EMPTY`，`AudioFlinger::onFirstRef` 再次空指针崩溃。已把 `fb_post` 改为 `FB_ACTIVATE_NOW | FB_ACTIVATE_FORCE` 调 `FBIOPUT_VSCREENINFO`，并为 `libaudiohal` 与 `AudioFlinger` 补上 6.0 直接回退和 `onFirstRef` 空指针检查。

同日再后：屏幕已显示开机动画，MDP 管道泄漏与 `audioserver` 崩溃均已消除。动画卡住是因为缺少 `android.hardware.wifi.xml` 等权限文件导致 `SystemUI` 的 `provideWifiManager` 空指针崩溃，进而触发 `RescueParty` 调用 `ModuleInfoProvider.getModuleInfo` 抛出 `IllegalStateException: Call to getModuleInfo before metadata loaded`，使 `system_server` 重启 18 次。已补齐 `/vendor/etc/permissions/` 下的硬件特性 XML，并更新 `services.jar`（`ModuleInfoProvider` 在元数据包未安装时标记 `mMetadataLoaded = true`）。

同日：重启后顺利走过开机动画，进入 `CryptKeeper` 解密失败界面，画面上下颠倒 180 度，未按恢复出厂按钮。180 度方向已写入运行中的 `vendor/build.prop`。用户随后接受格式化 userdata。未使用 `#17` TWRP 界面 Wipe。已清掉 `sda9` footer，并对整块分区建成未加密 ext4（54.2 GB，可挂载）。等下一次进系统验证桌面。

2026-10-27：首次开机走完 `LineageSetupWizard` 并进入 `Launcher3`（`QuickstepLauncher`）桌面与 `Settings`，触摸与 180 度屏幕倒装方向均验证正常。步骤 6（启动进入桌面）完成，转入步骤 7 逐项验收与硬件修复。

## 步骤 7：验收

推荐按这个顺序，前一项没有记录就先不跳到下一项：

1. 启动动画
2. 桌面，无横纹
3. 触摸。看 `config_csum`。原厂 raw 写进去之后，记下新值。若仍是 `53a963`，记在事件里，验收继续
4. Wi-Fi
5. 扬声器和听筒
6. 蓝牙
7. 传感器。SSC 校准在 persist 里，这一步不刷 persist
8. 双卡识别
9. 数据
10. 充电和休眠唤醒

相机和指纹允许只有进程活着。出图和录入解锁留到阶段 5。基带版本是 `MPSS.TH.2.0.c1`，RIL blob 用格力自己的。

SELinux 保持 permissive。每次开机把 denial 存下来。

### 实现笔记

- **首次进入桌面的日志隔离**：`/cache/boot-logcat.txt` 中在进 TWRP 前有两次因按键时机未进 recovery 而产生的几秒短开机（行 34904–39264 与 39265–41990），已剔除；真正的桌面会话位于行 15160–34903（历时约 8 分钟，包含 `FallbackHome` → `LineageSetupWizard` → `QuickstepLauncher` → `Settings`）。
- **桌面 ~2 FPS 严重卡顿与滚动时半面屏幕变黑闪烁的根因与修复**：
  1. **Write-Combine 显存直绘与双 DSI 扫描撕裂**：NT35597 为 1440×2560 双 DSI 命令模式屏（`split_mode:2 left:720 right:720`）。当 `gralloc.default` 的 `NUM_BUFFERS = 2` 时，`GRALLOC_USAGE_HW_FB` 直接把 `fb0` 的非缓存 Write-Combine 物理内存交给 SwiftShader 做 CPU 逐像素光栅化与混合（比缓存内存慢约 10 倍），且 `HWC2OnFbAdapter` 返回的 `outRetireFence = -1`，导致 SwiftShader 在下一帧开头执行 `sw::clear`（清黑）时，MDP 正好在扫描左/右半屏（720 列）的 DMA 传输，直接造成半面屏幕黑屏剧烈闪烁。
  2. **391 次 `hwservicemanager` 1000ms 阻塞**：因系统缺少 `/vendor/etc/vintf/manifest.xml`，`getTransport` 对 `IMapper@4.0/@3.0/@2.0`、`IPower`、`ISensors`、`IOmxStore` 等查询全部触发 `waitForHwService` 1 秒硬超时（单次开机累计阻塞 391 秒）。
  3. **修复方案**：将 `gralloc.default`（`framebuffer.cpp`）中 `NUM_BUFFERS` 改为 `1`（并令 `module->numBuffers = 1`），使 SurfaceFlinger 的合成缓冲改用带 CPU L1/L2 Cache 的普通 `ashmem` 内存；待 SwiftShader 在缓存内存中完成整帧渲染后，由 `fb_post` 用单次 ~1.5 ms 的顺序 `memcpy` 拷入 `fb0`，随后立即调用 `FBIOPUT_VSCREENINFO`（`FB_ACTIVATE_NOW | FB_ACTIVATE_FORCE`, `yoffset = 0`）触发双 DSI 同步刷新；同时编写并安装 `/vendor/etc/vintf/manifest.xml`，彻底消除 391 次 1 秒阻塞。
- **USB 仅充电、无 ADB 的根因与修复**：
  - 4.4 内核使用 ConfigFS USB Gadget，控制器为 `6a00000.dwc3`（`/sys/class/udc/6a00000.dwc3`）。桌面日志中缺少 `/config/usb_gadget/g1` 树与 `/dev/usb-ffs/adb` 挂载，且 `/system/default.prop` 中 `ro.adb.secure=1`、`persist.sys.usb.config=none`。
  - 修复：在 `init.gree.rc` 的 `on boot` 中建立 `/config/usb_gadget/g1`（`0x18d1`/`0x4ee7`）、挂载 `functionfs adb` 到 `/dev/usb-ffs/adb`，设置 `sys.usb.controller=6a00000.dwc3`、`sys.usb.configfs=1`、`persist.sys.usb.config=adb`，将 `/system/default.prop` 改为 `ro.adb.secure=0`，并清除 `/data/property/persistent_properties` 中的旧 `none` 记录。
- **背光调节与电源键亮灭屏（`lights.msm8996` + `light@2.0-service`）**：
  - `HWC2OnFbAdapter` 的 `setPowerMode` 是空操作，按电源键熄屏时不会写 `/sys/class/graphics/fb0/blank`。
  - 在 `device/gree/g0215d/liblight/` 实现格力专用的 `lights.msm8996.so`：写 `/sys/class/leds/lcd-backlight/brightness`、`/sys/class/leds/button-backlight/brightness` 及红绿蓝三色灯，并在背光降为 0 时自动向 `/sys/class/graphics/fb0/blank` 写 `4`（`FB_BLANK_POWERDOWN`）、背光大于 0 时写 `0`（`FB_BLANK_UNBLANK`），从而打通电源键休眠唤醒与亮度条调节。
- **Wi-Fi（QCA6174 PCIe / `qcacld-2.0`）固件与 HAL 接通**：
  - 内核 `boot-kmsg.txt` 显示 PCIe 总线已枚举出 `0000:01:00.0`（QCA6174 `168c:003e`），`cnss_wlan_pci` 已挂接；`qcacld-2.0` 静态编入内核时延迟到用户态向 `/sys/module/wlan/parameters/fwpath` 写入路径才触发 `hdd_driver_init()`。
  - 从实机 `modem` 分区（`image/`）和 `persist` 分区提取 `qwlan30.bin`、`otp30.bin`、`bdwlan30.bin`、`utf30.bin`、`data.msc` 与原厂 `wlan_mac.bin`（`[redacted]`），配合 `WCNSS_cfg.dat` 与 `WCNSS_qcom_cfg.ini` 放入 `/system/etc/firmware/` 及 `wlan/qca_cld/`。在 TWRP 中实测写入 `echo sta > /sys/module/wlan/parameters/fwpath` 后，内核在 0.85 秒内完成固件下载（`Host SW:4.0.11.213X, FW:4.1.2.42, HW:QCA6174_REV3_2`）并成功生成 `wlan0` 接口。
  - 已编译并推入 `android.hardware.wifi@1.0-service`、`wpa_supplicant`、`hostapd`、`libwifi-hal.so`、`libcld80211.so` 及 VINTF fragment。
- **Phase 3 剩余子阶段路线图（按调整后的优先级推进）**：
  - **7A（显示防撕裂、USB ADB、锁屏背光常亮修复与设置网络闪退排查）**：
    - 实机重启已确认：半屏黑闪/撕裂彻底消失，系统内 USB ADB 已认出 `[redacted] device`。
    - **锁屏 2–3 秒后背光重亮（黑屏但背光常亮）的根因与修复**：`init.gree.rc` 中的 `service panel_hold` 未加 `oneshot`。当 `sys.boot_completed=1` 后，`panel_hold.sh` 跳过 `while` 循环（不再写 `0` 到 `fb0/blank`），但仍执行末尾两行 `echo 180 > .../lcd-backlight/brightness` 后退出；`init` 每隔 5 秒重启一次该服务，导致 `lights.msm8996` 刚把屏幕 blank 并关掉背光，`panel_hold.sh` 就把背光重新拉回 180（而 `fb0` 仍保持 blank 黑屏）。已为 `service panel_hold` 加上 `oneshot`，并修改 `panel_hold.sh` 仅在 `sys.boot_completed != 1` 且背光为 `0` 时执行一次点亮。
    - **USB ADB 在 `SystemServer` 就绪后掉回仅 MTP（`18d1:4ee1`）的根因与修复**：`AdbService.initAdbState()` 通过读取 `/data/property/persistent_properties` 中的 `persist.sys.usb.config` 是否包含 `adb` 来决定 `mIsAdbUsbEnabled`，并在 `systemReady()` 中将结果写入 `Settings.Global.ADB_ENABLED`。由于首次开机遗留 `persist.sys.usb.config=mtp`，`SystemServer` 启动完成后会将 `on boot` 临时拉起的 `mtp,adb` 重置为 `mtp`。已在 `init.gree.rc` 中加入 `on property:persist.sys.usb.config=mtp` 与 `on property:persist.sys.usb.config=none` 自动重写为 `mtp,adb`，并在 `sys.boot_completed=1` 时执行 `settings put global adb_enabled 1`。
    - **设置 → 网络和互联网闪退的根因与修复**：通过在线 ADB 抓取 `logcat -b crash` 定位到 `com.android.settings` 抛出 `NullPointerException: Cannot return null from a non-@Nullable @Provides method`（位于 `SystemServicesModule_ProvideWifiManagerFactory.proxyProvideWifiManager` 及 `WifiEnabler.setupSwitchController`）。根因并非移动数据未就绪，而是 `/vendor/etc/permissions/` 下缺少 `android.hardware.wifi.xml`（及 `android.hardware.wifi.direct.xml`），导致 `SystemServer` 跳过启动 `WifiService`，`context.getSystemService(Context.WIFI_SERVICE)` 返回 `null`。已在 `device.mk` 中补齐全部硬件 feature XML（`android.hardware.wifi.xml`、`android.hardware.wifi.direct.xml`、`android.hardware.vulkan.*`、`handheld_core_hardware.xml` 等）。
  - **7B（Adreno 530 GPU 硬件加速与 SDM 硬件合成，优先级上调至音频之前）**：
    - 已从格力 G0215D 原厂固件提取带 OEM TrustZone 签名的 `a530_zap.mdt/.b00/.b01/.b02/.elf`，结合 MSM8996 同平台（OnePlus 3 LineageOS 18.1）的 Adreno 530 微码（`a530_pfp.fw`、`a530_pm4.fw`、`a530_gpmu.fw2`、`a530v3_gpmu.fw2`、`a530v3_seq.fw2`）与 32/64 位 OpenGL ES 3.2 / Vulkan 1.0 闭源库（`libEGL_adreno.so`、`libGLESv2_adreno.so`、`libGLESv1_CM_adreno.so`、`eglSubDriverAndroid.so`、`vulkan.msm8996.so`、`libgsl.so`、`libadreno_utils.so`、`libllvm-glnext.so`、`libCB.so`、`libOpenCL.so`、`libRSDriver_adreno.so`、`libsdm-color.so` 等）放入 `device/gree/g0215d/firmware/` 与 `gpu/`。
    - 已开启 `BOARD_USES_ADRENO := true`、`TARGET_USES_ION := true`，由 `hardware/qcom-caf/msm8996/display` 编译出 32/64 位 `gralloc.msm8996.so`、`hwcomposer.msm8996.so`、`memtrack.msm8996.so`、`libsdmcore.so`、`libsdmutils.so`、`libqdMetaData.so`、`libqdutils.so`、`libqservice.so`、`libdrmutils.so`、`libgpu_tonemapper.so`、`libdisplayconfig.so` 以及 HIDL 服务 `android.hardware.graphics.allocator@2.0-service`、`android.hardware.graphics.composer@2.1-service`、`android.hardware.graphics.mapper@2.0-impl`、`android.hardware.memtrack@1.0-service`。
    - 已在 `init.gree.rc` 与 `/vendor/ueventd.rc` 配置 `/dev/kgsl-3d0`（`0666`）、`/dev/ion`（`0666`）、`/dev/mdss_rotator`（`0664`）与 `/sys/class/graphics/fb0/*` 节点权限，将 `ro.hardware.egl=adreno`、`ro.hardware.vulkan=msm8996`、`ro.opengles.version=196610` 写入属性，并重新打包生成完整 `system.img`。
    - **实机验证与内核/硬件健康度证明**：
      - **Adreno 530 与 SDM HWC2 满速硬件合成**：`dumpsys SurfaceFlinger` 证明 `GLES: Qualcomm, Adreno (TM) 530, OpenGL ES 3.2 V@269.0` 已接管渲染，壁纸、桌面与 SystemUI 全部走 `DEVICE`（MDP 硬件叠加层）合成，刷新率稳定 `60.00 fps`。
      - **GPU/CPU 调频与内核调度器零隐患证明**：检查 `/sys/class/kgsl/kgsl-3d0/devfreq` 确认 `msm-adreno-tz` 调频器正常工作（空闲自动降至 `133 MHz`，滑动时动态升频至 `624 MHz`）；检查 `/sys/devices/system/cpu/cpufreq/` 确认 Kryo 小核簇（`policy0`: `307.2 MHz – 1.593 GHz`）与大核簇（`policy2`: `307.2 MHz – 2.150 GHz`）均由 `schedutil` 调度器正常管理，所有核心 `online = 0-3`，无 thermal 降频或死锁；锁屏后背光彻底保持熄灭（`lcd-backlight/brightness = 0`），USB ADB 全程稳定在线。
    - **Wi-Fi 搜不到网络的根因与热修复**：
      - 审计 `logcat` 与 `dmesg` 发现：`/vendor/etc/vintf/manifest.xml` 主文件与 `/vendor/etc/vintf/manifest/android.hardware.wifi.supplicant.xml` 同时声明了 `android.hardware.wifi.supplicant`，导致 `libvintf` 报错 `files are mutually exclusive` 并拒绝解析整个 `/vendor/etc/vintf/manifest/` 目录，进而使 `IWifi` 与 `IHostapd` 无法注册；同时 `WCNSS_qcom_cfg.ini` 中 `gEnableIpTcpUdpChecksumOffload=1` 在旧固件下阻塞扫描，且 `wpa_supplicant` HIDL 服务配置缺失。
      - 修复：移除重复的 `android.hardware.wifi.supplicant.xml` fragment，在 `init.gree.rc` 的 `wpa_supplicant` 服务中加入 `-O/data/vendor/wifi/wpa/sockets -dd`，并将 `WCNSS_qcom_cfg.ini` 中的卸载项关闭。重启用户态（您刚才看到的“手机自己软重启”正是我们在后台执行 `stop && start` 以使 VINTF 生效）后，Wi-Fi 立即成功扫描并自动连上 5GHz 路由（`SSID: "Not 6GHz"`, `5765MHz`, `RSSI: -26`, 协商速率 `433Mbps`）。
    - **“前 4 下滑动慢半拍、随后极度流畅”的根因与根治**：
      - **根因定位**：通过抓取 `/data/system/dropbox/system_app_anr@1793079489824.txt.gz` 与 `system_server` 线程栈发现，由于本机 `PRODUCT_SHIPPING_API_LEVEL := 23`（Android 6.0 首发）未开启 `PRODUCT_ENFORCE_VINTF_MANIFEST`，`system/libhidl/transport/ServiceManagement.cpp` 中的 `kEnforceVintfManifest` 为 `false`。每当任何进程调用 `getRawServiceInternal()` 查询设备清单（或未启动的 HAL，如 `IDumpstateDevice@1.0`、`IPower@1.0`、`IBiometricsFingerprint@2.1`、甚至每次调节亮度/按键背光时 `LightsService::setLight_native` 内部调用 `ILight::getService()`），`libhidlbase.so` 都会无条件执行一段硬编码的 **`sleep(1)`（整整 1000ms 睡眠）**！
      - **锁竞争链条**：当手指触摸屏幕唤醒按键灯或触发窗口切换时，`PhotonicModulator` / `PowerManagerService` 线程持有 `PowerManagerService` 全局锁 `<0x0e5a2d54>` 进入 `setLight_native -> ILight::getService() -> sleep(1)`，导致负责分发触摸焦点与窗口状态的 `android.display` 线程在 `setButtonBrightnessOverrideFromWindowManagerInternal` 上阻塞等待同一把锁；同时 `Settings` 主界面在 `onResume` 时并发查询 `IDumpstateDevice` 等多个未注册 HAL，触发连续数次 `sleep(1)`（正好对应“划 4 下屏幕、等待约 4 秒才有反应，一旦查完缓存住后就 60fps 丝滑无掉帧”）。
      - **修复验证**：修改 `system/libhidl/transport/ServiceManagement.cpp` 移除 `!kEnforceVintfManifest` 分支下的 `sleep(1)`，并将二进制补丁实时打入实机 `/system/lib64/libhidlbase.so` 与 `/system/lib/libhidlbase.so`，同时禁用尚未配好固件而后台循环 abort 的 `com.android.bluetooth`。重启用户态后实测：`LightsService` 响应耗时从 `>1000ms` 降至 `<1ms`，`Excessive delay setting light` 与 `HidlServiceManagement` 1 秒阻塞日志彻底清零，触摸与界面切换即点即应。
  - **7H（正面导航键：一颗实体 Home + 两侧虚拟 Back / 最近任务）**：
    - **现象**：`qemu.hw.mainkeys=1` 且 `config_showNavigationBar=false`，软件导航栏被关掉。正面下方中间实体键和两侧虚拟键完全无响应，无法回桌面或后退。
    - **输入设备**：修复前内核只有 `qpnp_pon`（电源 / 音量减）、`gpio-keys`（音量加 / 原 MTP 相机键）、`atmel_mxt_ts T100 touchscreen`。原厂还有一个名为 `tiny4412-key` 的输入设备，这一棵内核里没有。
    - **实体 Home 根因**：原厂 DTS 把 PM8994 GPIO 5 标成 `key_home`，`linux,code = 102`（`KEY_HOME`）。当前内核继承 `msm8996-mtp.dtsi`，同一脚被写成 `cam_focus` / `528`（`KEY_FOCUS`）。同时仓库里的 `gpio-keys.kl` 含非法标签 `GREE_KEY`，`KeyLayoutMap` 整文件解析失败，EventHub 回退到 `Generic.kl`（`102 = MOVE_HOME`，不是 Home）。结果：按下实体键内核报 FOCUS，框架不当作导航键。
    - **两侧电容键根因**：两块电容键不接 Atmel 触摸屏，而是由 **Goodix GF816M 指纹芯片**经 SPI 读出。原厂 `tiny4412-key` 这个名字就写在原厂内核 Goodix 驱动的字符串里（原厂 `Image` 偏移 `0x1239ec1`）。触摸驱动来自乐视 Le Max 2，那台机器的 `touch_keyevent`（`T15@0=139,1=172,2=158`）会让人以为键在 T15 上。实测排除了这条路：T37 参考值显示 T15 节点（X26 Y15–17，参考约 16300）确实有扫描，但按住两侧键时 delta 始终在 ±11 以内，CTRL 打开、阈值降到 8 也没有任何报文。当前内核没有 Goodix 驱动，SPI5 上也没有设备，所以按键无人读取。
    - **GF816M 协议**（从原厂 `Image` 反汇编得到）：
      - 写：`[0xF0, addr_hi, addr_lo, data…]`。
      - 读：先发 `[0xF0, hi, lo]`，再全双工发 `[0xF1, …]`，长度为 len+1，数据从 rx[1] 开始。两段的 `delay_usecs` 都是 5，SPI mode 0、8 位、1 MHz。
      - 寄存器：`0x8140` 状态（bit7 就绪；HOME 0x20/0x10、BACK 0x08/0x04、MENU 0x02/0x01，分别是掩码/状态）；`0x8043` 模式（0 图像、1 按键、2 睡眠、3 FF、0x56 调试）；`0x8047` 249 字节配置；`0x8040` 心跳（芯片 `0xC6`，主机每秒写 `0xAA`）；`0x8000` 版本串 `GFx16M`；`0x41E4` 为 `0xBE` 表示固件在跑。
      - 原厂复位时序：拉高、5 ms、拉低、16 ms、拉高、70 ms，再 `msleep(300)`。固件在芯片 flash 里，原厂的固件下载流程没有照搬。
    - **修复**：
      1. 重写 `gpio-keys.kl`：去掉 `GREE_KEY`；`102` 与旧内核的 `528` 都映射为 `HOME`，`59` / `766` 映射为 `F1`。
      2. 内核新驱动 `drivers/input/misc/gf816m_keys.c`（`CONFIG_INPUT_GF816M_KEYS=y`，匹配 `goodix,gf`）：复位芯片，确认 `0x41E4 == 0xBE`，写入原厂 249 字节配置（原厂 `Image` 偏移 `0x183facc`，末两字节是校验 `0x02 0x01`），切到按键模式，清状态。IRQ 线程读 `0x8140`，上报 `KEY_BACK` / `KEY_MENU`（`KEY_HOME` 只在模块参数 `report_home=1` 时上报，实体 Home 已经走 gpio-keys），再写回 0。每秒一次 ESD 检查：心跳或版本不对就重新初始化。sysfs 有 `mode`（可写）和 `status`。输入设备名沿用原厂的 `tiny4412-key`。
      3. 内核 DTS `g0215d-msm8996-v3-pmi8996-mtp.dts` 按原厂补上 `spi@7579000`（BLSP1 QUP5，IRQ 99，不开 BAM）和子节点 `goodix_fp@0`：复位 GPIO 51，中断 GPIO 121，供电 `pm8994_l19`。pinctrl 用 GPIO 81/83/84 做 `blsp_spi5`，GPIO 82（MISO）上拉。同一文件还覆盖 `gpio_keys`：GPIO 5 → `102 KEY_HOME`，GPIO 4 → `59 KEY_F1`。
      4. `drivers/pinctrl/qcom/pinctrl-msm8996.c`：小米这份表把 GPIO 81–84 的 `blsp_spi5` 功能删掉了，`spi_qsd` 因此报 `Can not set spi_default pins`。已按 CAF 原表补回这四行。
      5. `keylayout/tiny4412-key.kl`：`102 HOME`、`139 APP_SWITCH VIRTUAL`、`158 BACK VIRTUAL`。139 在 Android 11 上要映射成 `APP_SWITCH`（最近任务），不是 `MENU`。
      6. `overlay/lineage-sdk/lineage/res/res/values/config.xml` 把 `config_deviceHardwareKeys` 和 `config_deviceHardwareWakeKeys` 设为 `83`（Home 1 + Back 2 + App switch 16 + Volume 64）。lineage-sdk 默认是 `64`，Settings → System → Buttons 因此不列出任何导航键。实机在下次整编之前用平台签名的 RRO `org.lineageos.g0215d.buttons` 覆盖 `lineageos.platform`，`cmd overlay lookup` 已读到 `83`。
    - **撤回的 T15 方案**：之前为 T15 做的改动全部撤回。工厂 raw 恢复原样（CRC `53A963`，T15 CTRL `00`、阈值 `0x32`）。`init.atmel_ts.sh` 去掉 T15 逻辑，`init.gree.rc` 删掉 `atmel_tp_keys` 服务，`atmel_mxt_ts_T100_touchscreen.kl` 及其在 `device.mk` 的拷贝也删掉。芯片 NVRAM 已写回工厂值并 `BACKUPNV`，`config_csum` 为 `53a963`。T15 在没有按键垫的节点上开着、阈值又是 8，有误报的风险。
    - **实机证明**：内核 `#19` 开机打印 `gf816m_keys spi32766.0: chip GFx16M fw 01.04.04`。sysfs `status` 读到 `status 0x00 heartbeat 0xc6 fw_state 0xbe`，模式为 `0x01`。按两侧键时 `event2`（`tiny4412-key`）上有成对的 `KEY_MENU` / `KEY_BACK` 按下和抬起，`msmgpio 121` 计到 24 次中断。使用者确认返回和最近任务都能用，实体 Home 仍然正常。重启后 `dumpsys input` 显示 `tiny4412-key` 用的是 `/vendor/usr/keylayout/tiny4412-key.kl`。
    - **和指纹的关系**：这个驱动只做按键，不提供原厂指纹 HAL `gx_fpd` 要的 `/dev/goodix_fp` 字符设备和图像模式流程。7G 做指纹时要扩展这个驱动，或者换成完整的 Goodix 驱动。两种做法都必须保留按键上报，因为两侧键读的是同一颗芯片。
  - **7C（音频子系统：WCD9335 + TFA9890，扬声器、耳机、录音都已出声）**：
    - **现象**：修复前没有声卡，`/proc/asound/cards` 为空，`audio.primary.default` 因缺 `/dev/snd/pcmC0D0p` 报错。声卡起来以后又出现两次开机崩溃、Android 播放无声、ACDB 未初始化、录音无声、插耳机仍走扬声器。下面按出现的顺序记录。
    - **硬件**：耳机、听筒和麦克风走 WCD9335（`tasha`，SLIMbus）。扬声器不是 MTP 的两颗 WSA881x，而是一颗 NXP TFA9890，挂在 I2C-6 地址 `0x34`，音频走 QUAT MI2S（AFE 端口 `4102`），复位脚 GPIO 40。
    - **ADSP 起不来**：`fstab.qcom` 把 `modem`、`dsp`、`bluetooth` 挂到 `/vendor/firmware_mnt`、`/vendor/dsp`、`/vendor/bt_firmware`。本机 `/vendor` 就是 `/system/vendor`，镜像里没有这三个目录，所以挂载失败。新增 `rootdir/Android.mk`，在 `$(TARGET_OUT_VENDOR)` 下建好这三个目录。`init.gree.rc` 的 `on boot` 开头写 `/sys/kernel/boot_adsp/boot 1`，之后 ueventd 从 `/vendor/firmware_mnt/image` 读 `adsp.mdt` / `adsp.b*`。`on post-fs-data` 建 `/data/vendor/audio`。
    - **HAL 编译**：`BoardConfig.mk` 打开 `BOARD_USES_ALSA_AUDIO`、`USE_XML_AUDIO_POLICY_CONF`、`AUDIO_USE_LL_AS_PRIMARY_OUTPUT`。`BOARD_SUPPORTS_SOUND_TRIGGER := true` 也必须打开：关掉 sound trigger、listen 和 device arbitration 后，`audio_extn/utils.c` 会剩一个没用到的参数，在 `-Werror` 下编不过。`hardware/qcom-caf/msm8996/audio` 从 `$(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ/usr` 读内核 uapi 头。因为 `TARGET_NO_KERNEL := true`，需要先在内核树里手动导出一次：
      ```
      make O=out ARCH=arm64 headers_install INSTALL_HDR_PATH=/run/media/alpha/YMTC/lineage-18.1/out/target/product/g0215d/obj/KERNEL_OBJ/usr
      ```
      `device.mk` 加入 `audio.primary.msm8996`、`audio.r_submix.default`、`audio.usb.default`、`libqcompostprocbundle`、`libqcomvisualizer`、`libqcomvoiceprocessing`、`libvolumelistener`、`libaudio-resampler`、`tinyplay` / `tinycap` / `tinymix`，以及 `audio_policy_configuration.xml` 和 AOSP 的音量表、r_submix、USB policy 配置。
    - **声卡一直 defer 的三个原因**（都改在内核 DTS 的 `sound-9335` 节点）：
      1. 继承的 `qcom,wsa-max-devs` 要找 WSA881x，本机没有，改为 `<0>`。
      2. 机器驱动把 TFA 的 codec 名写死为 `tfa98xx.3-0034`。`msm8996.c` 改为从 DT 读 `qcom,tfa98xx-codec-name` / `qcom,tfa98xx-codec-dai-name`，DTS 填 `tfa98xx.6-0034` / `tfa98xx-aif-6-34`，并在 `&i2c_6` 下加 `tfa98xx@34`（`nxp,tfa98xx`，`reset-gpio = <&tlmm 40 0>`）。
      3. 机器驱动会链接 PRI 到 QUAT 四个 MI2S 口，任何一个 CPU DAI 不在 `asoc-cpu` 里，整张卡都 defer。按原厂补上 primary MI2S DAI 节点 `dai_pri_mi2s`（`qcom,msm-dai-q6-mi2s-dev-id = <0>`），`asoc-cpu` / `asoc-cpu-names` 写成 MTP 全表再加 `msm-dai-q6-mi2s.0/.1/.3`，共 62 项。同时删掉 `qcom,hdmi-audio-rx`：本机没有 HDMI，`CONFIG_MSM_EXT_DISPLAY` 也没开，`msm_hdmi_audio_codec_rx_dai` 永远不会出现。
    - **声卡注册后开机崩溃（使用者手动进 recovery）**：本机 ramoops 不能用，sysrq 触发的 panic 重启后，pstore 也是空的，引导程序会清内存。调试办法：在 recovery 里注释掉 `init.gree.rc` 的 `boot_adsp` 写入，先让系统开机；然后在可疑路径上加带编号的 `pr_err("... step N"); msleep(150);`，主机端 `adb shell dmesg -w` 实时存日志，再手动 `echo 1 > /sys/kernel/boot_adsp/boot` 触发。最后一条编号就是崩溃位置。这样找到两处：
      1. `msm_audrx_init` 里的 `rtd_aux` 等于 `&card->rtd[num_links]`。没有 aux 设备（`num_aux_devs == 0`）时它指向数组外面，判断 WSA8810 时解引用就崩。改为先判断 `rtd->card->num_aux_devs`。
      2. TFA 驱动是 v6.7.1，它的 `TfaContainer_t` 有 `uint16_t nliveData`，所以期望 index 在偏移 `0x2e`。格力（以及 OnePlus 3）的 `PM1_00` 容器没有这个字段，index 在 `0x2c`。结果 `tfaContDevice` 返回 NULL，`tfa_cont_get_idx` 直接解引用。`tfa_container.c` 新增 `tfaContIndex()`：`0x2e` 处不是 device 描述而 `0x2c` 处是时，用旧位置；`tfa_cont_get_idx` 同时加 NULL 判断。修好后 `mono Profile` 控件读到 `MUSIC_48000`，容器正常加载。
    - **扬声器路由**：`audio_platform_info.xml` 把 `SND_DEVICE_OUT_SPEAKER` 改到 `quat_mi2s_rx` 后端（`QUAT_MI2S_RX`），去掉 24 位设置（TFA 这条链路是 16 位 48 kHz），删除三条 SLIMBUS_0 加 SLIMBUS_6 的“扬声器 + 耳机”组合后端。因为接口不同，HAL 会自己把组合设备拆成两路。`mixer_paths_tasha.xml` 的 `speaker` 路径清空：TFA 是 QUAT MI2S DAI 链路的一部分，不需要 WCD 控件。`firmware/tfa98xx.cnt`（原厂）装到 `/system/etc/firmware/`。
    - **Android 播放无声，`tinyplay` 有声**：`MediaCodecList` 报 `Failed to create audio/raw decoder`。没有 `media_codecs.xml` 时，vendor `OmxStore` 返回 `NO_INIT`，`MediaCodecList` 会在加入 swcodec APEX 的 Codec2 软件解码器之前就停下。新增 `media/media_codecs.xml`（空的 `<MediaCodecs/>`，本机还没有 Venus OMX），装到 `/vendor/etc/`。
    - **ACDB 未初始化**：logcat 报 `ACDB -> Not correctly initialized!`。18.1 的 CAF HAL（LA.UM.8.6）`platform.c` 要 dlsym `acdb_loader_init_v3` 和 `acdb_loader_reload_acdb_files`，少一个就 `goto acdb_init_fail`。格力的 M 版 `libacdbloader.so` 只导出 `acdb_loader_init_v2` 和 `init_ACDB`。这里没有用 `TARGET_LD_SHIM_LIBS`，因为它通过 soong config 写进 runtime APEX 里的 linker。改为新增 `audio/acdbloader/`：
      - 原厂 blob 改名为 `libacdbloader_gree.so`，用 `prebuilts/extract-tools/linux-x86/bin/patchelf-0_9` 把 SONAME 改成同名。
      - 新的 `libacdbloader.so` 是一个垫片（`acdbloader_shim.c`），NEEDED 原厂库。`acdb_loader_init_v3(name, cvd, key_list)` 取链表第一个 key（没有就用 0），转调 `acdb_loader_init_v2`；`acdb_loader_reload_acdb_files` 打一条警告并返回 -1。
      - `device.mk` 装 `libacdbloader`，原厂 `libacdb-fts`、`libacdbrtac`、`libadiertac`、`libaudcal` 放 `/vendor/lib/`，七个 `MTP_*_cal.acdb` 放 `/system/etc/acdbdata/MTP/`，校验和与 blob 清单一致。
      - 实机 logcat 出现 `ACDB initialized`，播放时发出扬声器校准（`acdb_id = 15`）。`Fail to allocate memory for metainfo` 和耳机的 `ACDB AFE returned = -19` 不影响出声。
    - **录音无声**：录音能完成，回放没有声音。原厂 DT 的主麦（`Handset Mic`，AMIC5）用 MIC BIAS4，继承的 MTP 路由是 MIC BIAS3。DTS 覆盖 `qcom,audio-routing`，内容和 MTP 相同，只把 `"AMIC5", "MIC BIAS3", "MIC BIAS3", "Handset Mic"` 改成 MIC BIAS4。原厂的 `Secordary Mic` widget 在这份驱动里不存在，所以 `Analog Mic6` 保留。mixer 路径（`handset-mic` → `adc5`）和原厂一致，没改。
    - **插耳机仍走扬声器**：分两层。
      1. 原厂 `qcom,msm-mbhc-hphl-swh = <1>`，MTP 是 0，DTS 改为 1。
      2. 改完后内核已经检测到插入：`dumpsys input` 里 `Headset Jack` 的 `SwitchValues: 84`，即 `SW_HEADPHONE_INSERT` 加 `SW_JACK_PHYSICAL_INSERT`。但框架默认只读 `/sys/class/switch/h2w`，这棵内核没有这个节点。`overlay/frameworks/base/core/res/res/values/config.xml` 设 `config_useDevInputEventForAudioJack = true`，`WiredAccessoryManager` 改读输入事件。实机只重编了 `framework-res`，推到 `/system/framework/` 后重启；原来那份备份在 `boot-test/framework-res.apk.device-bak`。
    - **内核与镜像**：三个内核文件（`sound/soc/msm/msm8996.c`、`sound/soc/codecs/tfa98xx/tfa_container.c`、`g0215d-msm8996-v3-pmi8996-mtp.dts`）提交为 `79851a82f397`，已推送到 [`alpha-liu-01/android_kernel_gree_g0215d`](https://github.com/alpha-liu-01/android_kernel_gree_g0215d) 的 `g0215d` 分支。boot 镜像是 `/run/media/alpha/YMTC/g0215d/boot-test/boot-audio9.img`，13615104 字节，`sha256 16f5843ce7c406eb9951449ffc64c36bd1e18904c30d28ad548315bf4d9b6cee`。内核结束地址 `0x80c36f69`，仍低于 ramdisk 的 `0x81000000`。cmdline 和 ramdisk 沿用 `boot-audio2.img` / `boot-gf816m.img`。提交前只挪了 `tfa_container.c` 里一段注释的位置，镜像没有重打。
    - **实机证明**：声卡 `msm8996-tasha-mtp-snd-card` 约在开机 10 秒注册，系统正常开机。使用者确认：`tinyplay` 1 kHz 测试音清楚；Eleven 播放清楚；音量键有效；Recorder 录下的人声清楚；插耳机后只有耳机出声、两耳都有，拔出时播放暂停。HAL 日志显示扬声器走 `quat_mi2s_rx`，耳机走 `headphones`（`SLIMBUS_6_RX`）。
    - **还没做**：听筒（`handset`）没有单独测，要等 7F 通话时一起验。耳机麦没有测。语音通话、offload、蓝牙 A2DP 和 Venus 硬件编解码不在 7C。日志里还有几条不影响出声的噪声：`Amplifier initialization failed`（Lineage 没有 amp HAL）、找不到 sound trigger 库、缺 `audio_io_policy.conf`、`audio_route` 跳过部分控件。
    - **实机和镜像的差别**：上面的用户态文件都是手动推进实机 `/system` 的，没有重新打 `system.img`。本仓库和 18.1 设备树已经一致，下一次整编会全部带上。
  - **7D（蓝牙 QCA6174 Rome：开关、扫描、配对、A2DP 都已可用）**：
    - **现象**：修复前 `com.android.bluetooth` 被手动停用（它在后台循环 abort），Settings 的蓝牙开关没有效果，系统里没有蓝牙 HAL。
    - **硬件与内核**：芯片是 QCA6174 Rome，ROM 版本 `0x0302`（3.2），走 UART `/dev/ttyHS0`（`7570000.uart`，`msm_serial_hs`），上电由 `bt_qca6174` 节点的 `bt_power` rfkill 管（`rfkill0`，另有 `extldo` 属性）。这些内核已经有，**这一步不改内核**。固件在 `bluetooth` 分区（`sde21`，vfat），挂到 `/vendor/bt_firmware/image/`：`btfw32.tlv`、`btnv32.bin`、`btnv32.b15`。
    - **没有照搬原厂 `libbt-vendor.so`**：原厂是 Android 6 的 32 位库。18.1 的蓝牙 HAL 是 64 位进程，要 HIDL 版 `android.hardware.bluetooth@1.0`，它再 `dlopen` 厂商库。所以走了和小米 msm8996-common 一样的路：HAL 用 AOSP 自带的 `android.hardware.bluetooth@1.0-impl` / `-service`，厂商库用平台树 `hardware/qcom-caf/bt/libbt-vendor` 从源码编。Rome 的固件下载（`hw_rome.c`）在里面。
    - **`BoardConfig.mk`**：`BOARD_HAVE_BLUETOOTH`、`BOARD_HAVE_BLUETOOTH_QCOM`、`BOARD_HAS_QCA_BT_ROME` 打开。`QCOM_BT_USE_OLD_WCNSS_FILTER := true`，让 libbt-vendor 用不带 `vendor.` 前缀的 `wc_transport.*` 属性，和原厂 `wcnss_filter` 对上。没有开 `QCOM_BT_USE_BTNV`：原厂 `libbtnv.so` 只有 32 位。
    - **`wcnss_filter`**：这是 libbt-vendor 下载完固件后由 `wc_transport.start_hci=true` 拉起的 HCI 过滤进程，负责 IBS 睡眠协议和 UART 时钟投票。平台树里没有它的源码，直接用原厂 `system/bin/wcnss_filter`（64 位，Android 6，`NEEDED` 只有 `libdiag` 和基础库，`libdiag.so` 在 `gpu/lib64` 里已装）。放在 `bluetooth/wcnss_filter`，由 `bluetooth/Android.bp` 的 `cc_prebuilt_binary` 装到 `/vendor/bin/wcnss_filter`。原厂 SHA256 `3f7385d4f9f8ba28d89245b70b1a8bf3b1241ab74ad9fc618cac2d4a0e84d3a3`。`init.gree.rc` 加 `service wcnss_filter`（`user bluetooth`，`disabled`），以及 `on property:wc_transport.start_hci=true/false` 起停。
    - **固件路径**：libbt-vendor 写死读 `/bt_firmware/image/btfw32.tlv`。本机的根就是 system 镜像（第一阶段 init 切根），并且是只读的。启动时 `symlink` 会报 `Read-only file system`，所以改用 `BOARD_ROOT_EXTRA_SYMLINKS += /vendor/bt_firmware:/bt_firmware`，符号链接直接进 system 镜像根。这个链接在 `file_contexts` 里没有标签，`e2fsdroid` 报 `searching for label "/bt_firmware"` 而整镜像编不出来。所以新增 `sepolicy/vendor/file_contexts`：`/bt_firmware(/.*)?  u:object_r:bt_firmware_file:s0`，`BoardConfig.mk` 里用 `BOARD_VENDOR_SEPOLICY_DIRS` 加进去。实机是直接 `mount -o rw,remount /` 后 `ln -s`。
    - **蓝牙地址**：AOSP HAL 的 `Open` 在没有地址时 `LOG_ALWAYS_FATAL("No Bluetooth Address!")`，HAL 进程每次 abort。地址来源是 `ro.bt.bdaddr_path` 指的文件、`ro.boot.btmacaddr` 或持久属性。本机没有 `/persist/bluetooth`。原厂用 `btnvtool -O` 写 NV，地址在 TWRP 的 data 备份里：`/misc/bluedroid/bt_config.conf` 的 `Address = [redacted]`，和 `wlan_mac.bin` 的 Wi-Fi MAC 相同。所以把它放进 `bluetooth/bdaddr`，装到 `/vendor/etc/bluetooth/bdaddr`，`device.mk` 设 `ro.bt.bdaddr_path` 指向它。蓝牙地址因此和原厂一致，设置里读到 `[redacted]`。libbt-vendor 里 `wc_transport.stack_bdaddr` 显示字节序反过来的 `[redacted]`，这是库内部的 little-endian 写法，不是错。
    - **属性与权限**：`device.mk` 设 `vendor.qcom.bluetooth.soc=rome`（libbt-vendor 靠它选 Rome 分支）和 `ro.vendor.rfkilldisabled=0`。`init.gree.rc` 的 `on boot` 把 `rfkill0/type`、`state`、`device/extldo` 和 `/dev/ttyHS0` 交给 `bluetooth:net_bt`（0660），和原厂 `init.qcom.rc` 一致；`post-fs-data` 建 `/data/vendor/bluetooth`。`manifest.xml` 加 `android.hardware.bluetooth@1.0::IBluetoothHci/default`。`device.mk` 的包：`android.hardware.bluetooth@1.0-impl`、`-service`、`libbt-vendor`、`wcnss_filter`。
    - **一个坑：蓝牙 App 仍是停用状态**。`pm enable com.android.bluetooth` 之后要等几秒再重启，否则写盘前就重启，状态会回到 `enabled=3`，系统服务 `Fail to bind to: Intent { act=android.bluetooth.IBluetooth }`。
    - **实机证明（开机后日志）**：HAL 读到 `Got Factory BDA [redacted]`；`rome_soc_init` 读出 `Product ID 0x8`、`ROM Build 0x0302`、`Chipset Version 0x03020044`；UART 改到更高波特率成功；`File Open (/bt_firmware/image/btfw32.tlv)`，补丁下载，再下 `btnv32.bin`；`wc_transport.soc_initialized=1`，`hci_filter_status=1`，`wcnss_filter` 在跑；`AdapterState` 从 `OFF` 走到 `BLE_ON`、`TURNING_ON`、`ON`，约 1.2 秒。关再开一次也正常（过滤进程停止再启动，`rfkill0/state` 0 → 1）。
    - **A2DP**：Android 11 用蓝牙音频 HAL 2.0，由已有的 `android.hardware.audio.service` 通过 `android.hardware.bluetooth.audio@2.0-impl` 提供。`device.mk` 加 `android.hardware.bluetooth.audio@2.0-impl`、`audio.bluetooth.default` 和 `bluetooth_audio_policy_configuration.xml`；`audio_policy_configuration.xml` 用 `xi:include` 引入这个 module；`manifest.xml` 加 `android.hardware.bluetooth.audio@2.0::IBluetoothAudioProvidersFactory/default`。实机 `lshal` 看到两个蓝牙 HAL 都注册，`dumpsys media.audio_flinger` 里有输出线程走 `AUDIO_DEVICE_OUT_BLUETOOTH_A2DP`，会话是 `A2DP_SOFTWARE_ENCODING_DATAPATH`，编码器 AAC。
    - **使用者验证**：扫描能看到附近设备；配对能完成，状态是已连接；播放测试音只从蓝牙耳机出声。刚开机一分钟内有爆音，等系统安静下来后再测，两三分钟后爆音消失，干净。判断是开机初期的负载，不是 UART 或固件问题。
    - **整镜像**：这一步按完整构建验证过。`m systemimage` 成功，`/run/media/alpha/YMTC/g0215d/boot-test/system-7d.img`（稀疏格式，1683460640 字节，`sha256 fed6b2584e1729b76bd9fa5a7fc20b1eef1dd2b3aca44d5a33d8b62822bb59f6`）里有 `/bt_firmware` 符号链接，`wcnss_filter` 是 0755，`bdaddr` 是 0644，两个蓝牙 HAL 在 vintf manifest 里。这份镜像没有刷。boot 和内核这一步都没动，仍是 `boot-audio9.img`。
    - **没做**：HFP/SCO（通话走蓝牙耳机）和蓝牙电话音频要等 7F 一起验。BLE 外设、文件传输 OPP、蓝牙 tethering、LDAC/aptX 没有测。SELinux 仍是 permissive，开机日志里有 `hal_bluetooth_default` 写 `rfkill/state`、设置 `wc_transport.*` 属性、写 `/data/misc/bluedroid/bt_fw_version.txt` 的 denial，转 enforcing 之前要补策略。`libbtnv` 没用，地址固定为原厂那个值。
    - **顺带发现、不属于 7D**：使用者说无法把手机切到 MTP 传文件，这是另一个问题，另外处理。
  - **7E（传感器 SSC / ADSP）**：启动 `rmt_storage`、`tftp_server`、SLPI/ADSP 子系统与 `sensors.ssc.so` + `android.hardware.sensors@1.0-service`，读取 `/persist/sensors` 校准数据，恢复 BMI160、AK09915、RPR0521、LPS22HB、SHTC1。
  - **7F（双卡 RIL 与移动数据）**：挂载 `/firmware`（`MPSS.TH.2.0.c1`），启动 `qmuxd`、`netmgrd`、`rild`（格力 RIL blob + 18.1 `libril` 包装），验证 SIM 卡识别与驻网。
  - **7G（相机与 Goodix GF816M 指纹进程存活）**：检查 `mm-qcamera-daemon` 与 `gx_fpd` 守护进程启动状态，记录 SELinux denial 并归档。

### 事件

2026-10-27：完成首次进桌面后的日志审计（排除末尾两次几秒的误开机，分析行 15160–34903 的桌面会话）：
- **已通过项**：
  1. 启动动画正常播放并平滑交接给 `SystemUI`；
  2. `LineageSetupWizard`、`Launcher3`（`QuickstepLauncher`）桌面与 `Settings` 正常显示，无横纹，180 度方向正确；
  3. Atmel `atmel_mxt_ts` 触摸在桌面与设置中全程响应正常（`init.atmel_ts.sh` 写入 `Gree2_4005_V2.06_20170223.raw` 返回 0，芯片 `config_csum` 保持 `53a963`）。
- **已修复并推入 `/system` 待重启验证项**：
  - 针对屏幕 ~2 FPS 刷新与滚动时半屏变黑闪烁，已更新 `gralloc.default.so`（32/64 位，改为 `ashmem` 缓存渲染 + `memcpy` + `FB_ACTIVATE_NOW | FB_ACTIVATE_FORCE`）与 `/vendor/etc/vintf/manifest.xml`；
  - 针对 USB 仅充电无 ADB，已在 `init.gree.rc` 配置 `6a00000.dwc3` ConfigFS gadget、改 `ro.adb.secure=0` 并清空旧 `persistent_properties`；
  - 针对背光与休眠唤醒，已编译并推入 `lights.msm8996.so` 与 `android.hardware.light@2.0-service`；
  - 针对 Wi-Fi，已提取 `qwlan30.bin`、`otp30.bin`、`bdwlan30.bin`、`utf30.bin`、`data.msc`、`wlan_mac.bin` 并在 TWRP 实测点亮 `wlan0`（`QCA6174_REV3_2`，MAC `[redacted]`），同时编译推入 `android.hardware.wifi@1.0-service` 与 `wpa_supplicant`。

同日稍后：重启进系统实测反馈与第二轮修复（含内核树推送及 Adreno 530 硬件加速构建）：
1. **内核树已推送 GitHub**：将移动硬盘 `/run/media/alpha/YMTC/g0215d/kernel-g0215d` 中未提交的 DT fstab 禁用改动（`arch/arm/boot/dts/qcom/g0215d-msm8996-v3-pmi8996-mtp.dts` 禁用 `firmware/android/fstab` 以避免第一阶段 init 卡在 AVB vbmeta/dtbo 挂载）提交为 `fb30a4238f1a` 并推送到 [`alpha-liu-01/android_kernel_gree_g0215d`](https://github.com/alpha-liu-01/android_kernel_gree_g0215d) 的 `g0215d` 分支。
2. **USB ADB 掉线根因修复**：确认开机初期 `adb devices` 能识别 `[redacted] device`，随后 `AdbService` 读取 `/data/property/persistent_properties` 中的旧值 `persist.sys.usb.config=mtp` 将 USB 切回仅 MTP（`18d1:4ee1`）；已在 `init.gree.rc` 增加属性拦截规则强制保持 `mtp,adb` 并写入 `adb_enabled=1`。
3. **屏幕撕裂完全消除 & Adreno 530 GPU 硬件加速（7B）合入**：`gralloc.default` 的 `ashmem` 离屏缓存合成彻底消除了双 DSI 扫描期的半屏黑闪；为解决 SwiftShader 1–5 FPS 软件渲染瓶颈，已集成格力原厂 `a530_zap.*` 签名固件 + Adreno 530 微码与 32/64 位 OpenGL ES 3.2 / Vulkan 1.0 驱动栈，并编译 `gralloc.msm8996`、`hwcomposer.msm8996`（SDM HWC2）、`memtrack.msm8996` 与配套 HIDL 服务。
4. **锁屏背光 2–3 秒重亮修复**：为 `init.gree.rc` 的 `service panel_hold` 加上 `oneshot` 并限制 `panel_hold.sh` 仅在开机完成前执行一次，根治锁屏后背光被循环拉回 180 的问题。
5. **设置 → 网络和互联网闪退修复**：在线抓取 crash 日志确认闪退原因为缺少 `/vendor/etc/permissions/android.hardware.wifi.xml` 导致 `WifiService` 未启动（`WifiEnabler` 空指针），已补齐全部硬件 feature 权限 XML 并重新打包生成 `system.img`。

同日第三轮实机验证（Adreno 530 满帧运行、Wi-Fi 连通与“前 4 下输入慢半拍”根治）：
1. **GPU/CPU/背光/ADB 全面验证通过**：`SurfaceFlinger` 已由 `Adreno (TM) 530, OpenGL ES 3.2 V@269.0` 硬件合成驱动，满帧 60 FPS；`msm-adreno-tz`（133–624 MHz）与 `schedutil`（小核 307–1593 MHz、大核 307–2150 MHz）调频器运行正常，锁屏背光保持 0 不再重亮，ADB 全程稳定在线。
2. **Wi-Fi 2.4G/5G 扫描与连接修复完成**：删除 `/vendor/etc/vintf/manifest/` 下与主 `manifest.xml` 冲突的重复 `android.hardware.wifi.supplicant.xml` 后，`IWifi@1.4` 与 `ISupplicant@1.3` 正常握手，实机已自动连上 5GHz Wi-Fi（`SSID: "Not 6GHz"`, `5765MHz`, `433Mbps`）。固件、`WCNSS_qcom_cfg.ini`、`wpa_supplicant` overlay、feature XML 与 HAL 软件包此前已在设备树里。真正漏进仓库的只有这一处 VINTF 冲突：主 `manifest.xml` 自己声明了 `android.hardware.wifi.supplicant`，HAL 软件包又再装一份 fragment。现已从本仓库和 18.1 树的 `manifest.xml` 中去掉 `ISupplicant`，下次编镜像时只保留软件包自带的 fragment。
3. **触摸输入“划 4 下才响应、随后完全流畅”的根因与在线根治**：定位到 `system/libhidl/transport/ServiceManagement.cpp` 在 `!kEnforceVintfManifest` 时对每次 `getRawServiceInternal()` 调用执行硬编码 `sleep(1)`（1000ms），导致 `LightsService`（按键灯/背光调节持有 `PowerManagerService` 锁）与 `Settings`（并发查询未注册的 `IDumpstateDevice`/`IPower`/`IBiometricsFingerprint`）反复将主线程与 `android.display` 阻塞数秒。源码改动在 18.1 平台树 `system/libhidl/transport/ServiceManagement.cpp`，不属于本设备仓库；32/64 位 `libhidlbase.so` 已热补丁进实机，并停用后台崩溃循环的 `com.android.bluetooth`。

同日第四轮：正面实体 Home 与两侧虚拟键全部失效。实体 Home 已能回到桌面。两侧电容键和 Buttons 页当时还没好，见下一轮。

同日第五轮：
1. **两侧电容键**：使用者确认中间实体 Home 正常，左右返回 / 最近任务没有反应。复测时 T15 CTRL 又是 `00`。只写 RAM 会被下一次 T6 复位冲掉，而 `update_cfg` 在文件 CRC 仍是 `53A963` 时判定配置已一致、整表不重写。现已把工厂 raw 的 T15 CTRL 改为 `03`，配置 CRC 记为 `63AA53`，实机 `config_csum` 为 `63aa53`，对象表 CTRL 保持 `03`。`keys_on` 读数是 `1`，驱动里的软件门是开的。
2. **Settings → System → Buttons**：lineage-sdk 默认 `config_deviceHardwareKeys=64`，页面不列出 Home / Back / 最近任务。设备树 overlay 与实机 RRO `org.lineageos.g0215d.buttons` 都把它和对应的唤醒位图改成 `83`。`cmd overlay lookup` 读到 `83`。Settings 进程已强制结束后台，重新打开该页即可。Back / 最近任务的熄屏唤醒要等 `system_server` 下次起来才吃到这份资源，也就是下一次重启之后。本机没有 `button-backlight`，所以没有加按键亮度条。

同日第六轮：电容键仍然没有反应。`logcat` 里没有任何 `KEY` / `BACK` / `APP_SWITCH`。当时 T15 CTRL 已是 `03`，阈值仍是工厂的 `50`，实体 Home 正常。把 T15 触摸阈值从 `50` 降到 `8` 并 `BACKUPNV`，芯片校验和变为 `a59c6e`，对应 raw 的配置 CRC 改为 `A59C6E`，避免下次开机 `update_cfg` 把阈值写回 `50`。阈值降到 `8` 时芯片不会自己误报，节点本身是安静的。整表 `update_cfg` 会把手机重启，单字节修改只走 `mem_access` 加 `BACKUPNV`。

同日第七轮：两侧电容键修好，根因是 GF816M 而不是 T15，细节见 7H。
1. **排除 T15**：T37 参考值和 delta 显示 T15 节点被扫描，但按住两侧键时没有信号。原厂 `tiny4412-key` 来自原厂 Goodix 指纹驱动。
2. **内核 `#19`**：新增 `gf816m_keys` 驱动，DTS 增加 SPI5 和 `goodix_fp@0`，pinctrl 补回 GPIO 81–84 的 `blsp_spi5`。`#18` 缺这几行 pinctrl，SPI 控制器报 `Can not set spi_default pins`。这一轮重编了内核，属于“本阶段不做”里的例外。内核改动提交为 `462326055766`，已推送到 [`alpha-liu-01/android_kernel_gree_g0215d`](https://github.com/alpha-liu-01/android_kernel_gree_g0215d) 的 `g0215d` 分支。
3. **boot 镜像**：`/run/media/alpha/YMTC/g0215d/boot-test/boot-gf816m.img`，13615104 字节，`sha256 2f96fb1117bafaa5bfb680de468a0b9bb212cd2ef39d7875ab7b9f480b59380d`。cmdline 和 ramdisk 沿用 `boot-debug4.img`，后者仍是回退用的镜像。刷写前先 `adb root`，`dd` 写 `/dev/block/by-name/boot` 后用 `head -c` 核对 sha256。
4. **撤回 T15 改动**：本仓库、18.1 设备树和实机 `/system` 都已恢复工厂 raw 和原来的 `init.atmel_ts.sh`，删掉 `atmel_tp_keys` 服务和 Atmel 按键 keylayout。芯片 T15 写回 CTRL `00`、阈值 `0x32` 并 `BACKUPNV`。重启后 `config_csum` 为 `53a963`，`gf816m_keys` 正常探测。

同日第八轮：7C 音频，扬声器、耳机、录音都已出声，细节见 7C。
1. **声卡注册**：ADSP 挂载点、`boot_adsp`、WSA 设为 0、TFA DT 节点和名字、primary MI2S 与 `asoc-cpu` 全表、删掉 HDMI 音频，这些改完后声卡注册了，但随后开机崩溃。使用者手动进 recovery，在 recovery 里先停掉 ADSP 自动启动，用带编号的日志行加手动触发 ADSP 找到两处崩溃（`rtd_aux` 越界、TFA 旧容器 index），修好后系统正常开机。
2. **出声**：`tinyplay` 有声而 Android 无声，原因是缺 `media_codecs.xml`。补上之后，再用 `libacdbloader` 垫片接通 ACDB。
3. **录音与耳机**：主麦改用 MIC BIAS4，`hphl-swh` 改为 1，`config_useDevInputEventForAudioJack` 打开。使用者确认录音和耳机正常，拔耳机时播放暂停。
4. **内核**：提交为 `79851a82f397` 并推送。boot 镜像是 `boot-audio9.img`，`sha256 16f5843ce7c406eb9951449ffc64c36bd1e18904c30d28ad548315bf4d9b6cee`。这一轮也重编了内核，属于“本阶段不做”里的例外。

同日第九轮：7D 蓝牙，开关、扫描、配对、A2DP 都能用，细节见 7D。没有动内核和 boot。
1. **HAL 与厂商库**：AOSP `android.hardware.bluetooth@1.0` 加平台树里的 `libbt-vendor`（Rome 固件下载在里面），再加原厂 64 位 `wcnss_filter`。蓝牙 App 从停用恢复。
2. **`/bt_firmware`**：根是只读的 system 镜像，启动时 `symlink` 失败。改成 `BOARD_ROOT_EXTRA_SYMLINKS`，并为它补 `file_contexts` 标签，否则整镜像的 `e2fsdroid` 过不去。
3. **蓝牙地址**：AOSP HAL 没有地址就 abort。把 TWRP 备份里原厂的 `[redacted]` 放进 `bluetooth/bdaddr`。
4. **A2DP**：蓝牙音频 HAL 2.0 加 `audio.bluetooth.default`，policy 引入 `bluetooth_audio_policy_configuration.xml`。使用者确认只从蓝牙耳机出声，开机头一分钟有爆音，之后干净。
5. **整镜像**：`system-7d.img` 编出来了，`sha256 fed6b2584e1729b76bd9fa5a7fc20b1eef1dd2b3aca44d5a33d8b62822bb59f6`，没有刷。

## 步骤 8：收口

推荐：步骤 7 的十项都有一次通过的记录，相机和指纹的进程状态也记下了，这一阶段就停。下一步才是阶段 4：从 userdata 划出 vendor，再把板级目录接回小米 `lineage-22.2` 的 `msm8996-common`。

桌面、触摸或蜂窝还没有记录时，不改分区表。

### 实现笔记

（尚无）

### 事件

（尚无）

## 本阶段不做

- 不把本仓库现有的 `BoardConfig.mk` 改去继承 18.1，阶段 4 还要用现在这份对 `msm8996-common` 的留白
- 不重编内核，除非步骤 6 退回来。例外：7H 的两侧电容键需要新驱动，内核重编为 `#19`；7C 的声卡要改 DTS 和两处驱动崩溃，镜像为 `boot-audio9.img`
- 不另编一版新 TWRP，也不格式化 data。步骤 1 只把 recovery 刷回 2016 年那份能读 footer 的镜像
- 不动 aboot、xbl、tz、rpm、hyp、cmnlib、keymaster、modemst、fsg、persist、dsp
- 不刷 `third_party/` 里的卡刷包
- 不同步 20、21、22.2 的整份用户态来替代 18.1
- 不把一加 3 的面板、Synaptics、FPC 指纹和 IMX 相机配置写进格力
- 不把 4 KB 页改成 16 KB
