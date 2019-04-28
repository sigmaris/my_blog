---
title: Automating Debian install in QEMU
author: sigmaris
type: post
date: 2019-04-28T10:57:12+00:00
url: /2019/04/automating-debian-install-qemu/
categories:
  - linux
---
I recently wanted to automate building a headless Debian testing (codename "buster") virtual
machine, hosted on macOS, and it turned out to be somewhat more complicated than I expected, so I
thought I'd document it here for others' benefit.

Instead of installing VirtualBox, VMWare Fusion or Parallels which are quite heavyweight virtual
machine apps, I wanted to run a headless VM using QEMU, which can be installed easily using
[Homebrew][1]. QEMU now supports hardware accelerated x86 virtualisation on Macs using the
Hypervisor.framework built in to macOS.

The script and preseed file to perform the fully automated install is [here][2], and I'll explain
the details behind what it does in this post.

<!--more-->

The two key things needed for a fully automated install (i.e. no human interaction with the Debian
Installer) are:

* A way to supply a preseed file to the installer, via the initrd or a webserver.
* Some extra command line arguments to make the installer avoid human interaction and
  auto-configure networking.

The preseed file is a list of pre-supplied answers to questions asked during the OS installation
process and also questions asked during Debian package installs. The [Debian wiki][3] explains how
to supply the preseed file - it can be placed in the initrd.gz for the installer, or it can be
served via HTTP and a URL supplied to the installer, either via DHCP or manually entered in the
graphical installer.

As I wanted to avoid all manual interaction with the installer, I tried to script inserting the
preseed file in the initrd.gz of an installer ISO, but I found the normal `hdiutil` tool for
mounting ISOs on macOS would refuse to mount a Debian net install ISO. Without being able to mount
the ISO on the host, it'd be tricky to insert the file in the initrd.gz. So, since QEMU supports
serving DHCP and TFTP to network-boot virtual machines, I decided to try a network boot approach.

I found that the following QEMU `-netdev` parameters needed added to network boot the installer:

* `hostname=bustervm` - which tells the VM its hostname via DHCP.
* `domainname=localdomain` - which tells the VM its DNS domain name via DHCP.
* `tftp=tftpserver` - where the `tftpserver` directory contains an extracted Debian Installer
  netboot.tar.gz file.
* `bootfile=/pxelinux.0` - tells the VM to boot using `pxelinux.0` from the `tftpserver` directory.

and then the default pxelinux.cfg file from the Debian Installer netboot.tar.gz needed to be
modified to contain:

* `serial 0` - use the first serial port for a console, instead of a VGA display.
* `prompt 0` - don't prompt for a choice of what to boot.
* `default autoinst` - boot our label `autoinst` by default
* `label autoinst` - label this boot choice `autoinst`
* `kernel debian-installer/amd64/linux` - this is the unmodified path to the Linux kernel to boot
* `append <multiple boot parameters>` - each boot parameter is described below:
    * `initrd=debian-installer/amd64/initrd.gz` - provides the path to the unmodified `initrd.gz`
    * `auto=true` - tells the installer to autoconfigure network before fetching the preseed file
    * `priority=critical` - only show "critical" questions from debconf
    * `passwd/root-password-crypted=$CRYPTED_PASSWORD` - pre-supply a root password
    * `DEBIAN_FRONTEND=text` - use a text user interface suitable for a serial console
    * `url=http://10.0.2.2:4321/preseed.cfg` - URL to the preseed file on the VM host
    * `log_host=10.0.2.2 log_port=10514` - Log using syslog to the VM host
    * `--- console=ttyS0` - The `---` signifies further arguments should be added to the installed
      system's default kernel command line, here we tell Linux to use the first serial console.

To serve the preseed file, I ran a Python [SimpleHTTPServer][4] during the install. Since the
installer can be configured to log via the syslog protocol to a network host, I configured it to log
to the VM host, and then ran `netcat` on the VM host to listen for syslog traffic, and redirected
all its output to file - this is a quick'n'dirty way to produce a log file of the install.

To allow login to the created VM, my script generates a random password for the root account, and
will also add any SSH public keys it can obtain from the running SSH agent as authorized_keys for
the root account. As a final step, the VM grabs the authorized_keys file via the host's HTTP server.

Then I just run `qemu-system-x86_64` with a disk image attached and the network boot parameters, and
let it do all its work. Note the QEMU arguments `-machine accel=hvf -cpu host` which enable
Hypervisor.framework hardware-accelerated virtualisation, and `-nographic` which disables graphical
output and displays the serial console output in the terminal instead.

[1]: https://brew.sh/
[2]: https://gist.github.com/sigmaris/dc1883f782d1ff5d74252bebf852ec50
[3]: https://wiki.debian.org/DebianInstaller/Preseed
[4]: https://docs.python.org/2/library/simplehttpserver.html
