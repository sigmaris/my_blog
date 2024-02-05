---
title: NanoPC-T6 Notes
author: sigmaris
type: post
date: 2024-02-04T18:29:00+00:00
url: /2024/02/nanopc-t6-notes/
categories:
  - linux
---
Recently I've been following progress on support for the Rockchip RK3588 System-on-Chip in mainline Linux. I have been using a [RockPRO64](https://www.pine64.org/rockpro64/) single-board computer based on Rockchip's previous top-end SoC RK3399 for several years as a media centre running Kodi, on Debian with a [mainline Linux kernel](https://github.com/sigmaris/linux/releases/tag/6.1.23-rockpro64-ci) (plus some [patches](https://github.com/LibreELEC/LibreELEC.tv/tree/master/projects/Rockchip/patches) for improved multimedia support from the LibreELEC project).

I've been pretty satisfied with the support for RK3399 in mainline Linux, as opposed to a vendor BSP based on an old kernel like 4.4. The good level of upstream support is partly due to the fact the RK3399 was used in several Chromebook devices, and thanks to Chromium OS's "[Upstream First](https://www.chromium.org/chromium-os/chromiumos-design-docs/upstream-first/)" policy they contributed a large amount of support for the RK3399 in the open source projects used in Chromium OS, most importantly Coreboot, ARM Trusted Firmware and the Linux kernel.

The Rockchip SoCs after RK3399 haven't been used for ChromeOS devices as far as I know, but even so, upstream support for the new top-end SoC RK3588 has been improving bit by bit, mainly thanks to [Collabora](https://www.collabora.com) who have been working on [general kernel support](https://kernel-recipes.org/en/2023/schedule/getting-the-rk3588-soc-supported-upstream/) and userspace GPU drivers in Mesa, and Rockchip engineers have also been sending patches to upstream projects for the RK3588.

---

On a parallel thought-track, I have been thinking of replacing the home server I have in my closet - a repurposed desktop PC - with something that uses a bit less power and could save on electricity bills. It runs a RAID setup for storing a backup of my music, photos and so on, Home Assistant and Rhasspy for home automation, a Mastodon server instance, PostgreSQL to store the databases for the above, a MySQL server to store a shared Kodi library, and a few other services. None of these are utilized intensively, so they can all co-exist on one server with a Core i5 760 CPU and 24GB RAM. Actually only around 6GB RAM is used by the running services, with 13GB used for disk cache and buffers.

Given that electricity costs have risen significantly since 2022, I wondered if it was possible to replace it with something using less power when constantly running. Since there are several services running there, I wanted something more powerful than a Raspberry Pi 4, and I was looking at several RK3588 boards as they seemed powerful enough. The arrival of [support for the RK3588](https://review.trustedfirmware.org/c/TF-A/trusted-firmware-a/+/21840) in upstream ARM Trusted Firmware pushed me over the edge of deciding to buy one, and I found three boards that seemed to be in the right ballpark of cost, available interfaces and peripherals:

* [Xunlong Orange Pi 5 Plus](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5-plus.html)
* [FriendlyELEC NanoPC-T6](https://www.friendlyelec.com/index.php?route=product/product&product_id=292)
* [Radxa ROCK 5 Model B](https://wiki.radxa.com/Rock5/5B)

Out of these, the NanoPC-T6 was the most attractive due to its low cost and simple & reliable power input (it just takes 12V power via a barrel jack, versus the others which require non-standard USB-C 5V high current power supplies) and dual M.2 slots which could be used for PCIe expansion. The other two have a few plus points like more USB ports or removable eMMC storage, but neither of those were needed for the home server use-case. The model I eventually bought was the Nano-PC T6 2301 version, with 16GB RAM and 256GB eMMC soldered directly to the board.

I include below some notes I took while getting familiar with the device, getting mainline Linux to run on it and starting to build a server based on it.

## USB ports

The main downside of the original NanoPC-T6 (2301 model) is the relative lack of USB ports - only one USB 3.0 Type A and one Type C USB port are present. You can add another USB 2.0 port by using a Mini PCIe adapter like [this one](https://www.amazon.co.uk/dp/B08ML97QSF?psc=1&ref=ppx_yo2ov_dt_b_product_details), if you're not using the Mini PCIe slot for other purposes. There is only space for a small USB plug, so a right-angle adapter could be useful if you can find the right type. When I initially tried this, I found the Mini PCIe slot wasn't powered by default, but I created a [patch](https://lore.kernel.org/all/20240109202729.54292-1-sigmaris@gmail.com/) to the device tree fixing this, which is now included in the upstream Linux device tree repository.

FriendlyELEC have recently started selling an updated version, which they call NanoPC-T6 LTS (2310). The LTS version gets rid of the MiniPCIe slot and Micro SIM slot that were intended for use of a 4G/LTE modem, and adds two extra USB 2.0 ports, which were lacking on the original model.

## Screws

The screws used to retain the M.2 Key M and Key E modules are not the normal M2 x 2.5mm machine screws used for this purpose on most x86 motherboards, instead M3 x 2.5mm machine screws should be used. The mounting holes for a heatsink next to the main SoC are also sized for M3 screws, however --- as an odd one out --- the standoff for retaining the Mini PCIe card uses a M2.5 machine screw.

Despite the presence of 2 mounting holes for a heatsink, there doesn't seem to be any compatible heatsink or fan sold on FriendlyELEC's site, apart from the metal case which can act as a heatsink. For the time being, I've just fitted a small [thermal pad, heatsink and 5V fan](https://www.okdo.com/p/kksb-fan-with-heatsinks-for-rock-4-series-single-board-computers-low-profile/) from OKdo.

## SATA instead of PCIe on the M.2 Key E

Since the M.2 Key E slot is using one of the combination PCIe/SATA/USB PHYs for PCIe, in a similar design to how the RK3588 is connected to the Key E slot on the Radxa Rock 5B, we can use the [SATA breakout board](https://www.okdo.com/p/m-2-e-key-to-sata-breakout-board-for-use-with-rock-single-board-computers/) sold for use with the Rock 5B to physically connect a SATA drive to the Key E slot.

Note this is not a standard M.2 Key B SATA adapter, it is a specialised Key E breakout which is only compatible with these RK35xx boards which can be switched to talk SATA on some pins normally used for PCIe.

To get the OS to enable & use the SATA function, a device tree overlay is needed:

```devicetree
/dts-v1/;
/plugin/;

&{/usb@fcd00000} {
    status = "disabled";
};

&{/pcie@fe180000} {
    status = "disabled";
};

&{/sata@fe230000} {
    status = "okay";
};
```

Compile it with `dtc -O dtb -@ -o sata-on-m2-e-key.dtbo sata-on-m2-e-key.overlay.dts`, then --- assuming you're using an `extlinux.conf` file with boot options --- add `FDTOVERLAYS /path/to/sata-on-m2-e-key.dtbo` after the `FDT` line in `extlinux.conf` to get U-Boot to apply it to the device tree (U-Boot needs to have been compiled with `CONFIG_OF_LIBFDT_OVERLAY`).

## Use as a home server & NAS

As well as the miscellanous notes here, I intend to write more in a subsequent article about setting up a RAID array with SATA disks, particularly about powering the NanoPC-T6 and the drives with a suitable power supply.
