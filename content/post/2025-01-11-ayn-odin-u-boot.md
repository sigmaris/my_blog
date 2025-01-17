---
title: U-Boot for ayn Odin
author: sigmaris
type: post
date: 2025-01-11T19:21:35+00:00
url: /2025/01/ayn-odin-u-boot/
categories:
  - linux
---
Last year, I picked up a new [ayn](https://www.ayn.hk) Odin gaming handheld, and ended up working on installing Linux on it (regular Linux, not Android). I thought the process and things I learned during it would make for some good blog posts, so part of the way through the process I started writing down what I was doing, in the hope it would be interesting to others when published. This post will be the first in a series hopefully following the journey in getting full, or at least workable, support for it in upstream Linux so that anyone can install Linux on their Odin device and keep it up to date with the latest emulators, graphics drivers and so on.

The first step is to be able to boot a Linux upstream kernel on the device. The factory-supplied Android boot loader (ABL) is specialised for booting Android kernels, and will pass them an Android-specific device tree description of the hardware. It's not really usable for directly booting mainline Linux as the Android device tree has been designed differently from the upstream device trees that mainline Linux expects, so to boot mainline Linux I've been using U-Boot. U-Boot can be chain loaded from the ABL, then U-Boot can load the Linux kernel, initrd and (upstream-compatible) device tree and start the kernel. This is possible thanks to Caleb Connolly's extensive work on U-Boot for Qualcomm platforms which is covered in more detail in [this blog post](https://www.linaro.org/blog/initial-u-boot-release-for-qualcomm-platforms/).

# Building U-Boot (on a Linux system)

To build U-Boot from source, we need a few patches on top of the 2025.01 version which I've collected in [this branch](https://github.com/sigmaris/u-boot/commits/odin/):

```shell
git clone -b odin git@github.com:sigmaris/u-boot.git
cd u-boot
```

Set up the configuration, and compile U-Boot using the Odin device tree. Note that on x86 platforms you need the aarch64 GNU toolchain installed (and used by the CROSS_COMPILE=aarch64-linux-gnu- argument). For example, on Debian amd64, install the `gcc-aarch64-linux-gnu` package. If compiling on aarch64 linux, omit that part. Also remove the `-m2` part of the device tree name if you have the original Odin model rather than the M2 revision. 

```shell
make CROSS_COMPILE=aarch64-linux-gnu- O=.output qcom_defconfig
make CROSS_COMPILE=aarch64-linux-gnu- O=.output -j$(nproc) DEVICE_TREE=qcom/sdm845-ayn-odin-m2
```

Then we need to build an Android boot image out of U-Boot and the DTS for U-Boot to use. You need to have the `mkbootimg` utility from the Android tools, for example on Debian use `apt install mkbootimg` to get it.

```shell
gzip .output/u-boot-nodtb.bin -c > .output/u-boot-nodtb.bin.gz
cat .output/u-boot-nodtb.bin.gz .output/dts/upstream/src/arm64/qcom/sdm845-ayn-odin-m2.dtb > /tmp/uboot-with-dtb
mkbootimg --kernel_offset '0x00008000' --pagesize '4096' --kernel /tmp/uboot-with-dtb -o .output/u-boot.img
```

The file `.output/u-boot.img` is an Android boot image that can be booted by ABL on the device. But it contains an upstream device tree and Android will try and apply device tree overlays intended for an Android device tree over it, which will not work and probably break the device tree structure, preventing U-Boot from starting. So first we need to erase the `dtbo` partition containing device tree overlays on the Odin's internal storage. This can be done without affecting the Android install as there is an A/B dual slot partition system in place, so we can leave the Android `dtbo` partition alone, and erase the unused one to boot U-Boot and Linux.

# Writing U-Boot to a boot partition on the Odin

You'll need the `fastboot` CLI utility from Android tools for this. Connect the Odin to the computer via USB and power it on while holding down the Volume Down key, and it should boot up into "fastboot mode". It can then be controlled using `fastboot` on the computer. If you have `adb` for Android you can also run `adb reboot bootloader` while it's tethered and running Android, to reboot it into fastboot mode.

In fastboot mode, first determine which slot is currently active, assuming the device is currently set up to boot Android. It could be either `a` or `b`, as it flips over every time an Android system upgrade is applied.

```console
❯ fastboot getvar current-slot
current-slot: a
Finished. Total time: 0.001s
```

In this case slot `a` is currently used for Android, so use slot `b` for U-Boot and Linux. If your device has slot `current-slot: b` then substitute `a` in the subsequent commands:

```shell
fastboot erase dtbo_b
```

At this point it should be possible to do a "tethered" boot by changing to slot `b` where the `dtbo` partition has been erased and sending our `.output/u-boot.img` image using fastboot:

```shell
fastboot --set-active=b
fastboot boot .output/u-boot.img
```

After that, you should see the U-Boot logo appear and log some messages, sideways as the device uses a portrait-mode display panel even though it's a landscape-mode handheld...

To permanently install U-Boot to the internal storage, flash it to the `boot_b` partition, i.e. the slot corresponding to where we erased the `dtbo` partition, currently *not* used by Android:

```shell
fastboot flash boot_b .output/u-boot.img
```

To change back to booting Android instead of U-Boot, just use `fastboot --set-active=a` to switch back to the Android slot.

The next step is to build a disk image containing a Linux kernel and userspace files that we can write to a SD card, which U-Boot should then be able to find and boot from.
