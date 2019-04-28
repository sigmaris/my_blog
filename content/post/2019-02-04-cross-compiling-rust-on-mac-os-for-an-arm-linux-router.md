---
title: Cross compiling Rust on Mac OS for an ARM Linux router
author: sigmaris
type: post
date: 2019-02-04T22:57:12+00:00
url: /2019/02/cross-compiling-rust-on-mac-os-for-an-arm-linux-router/
autopostToMastodon-post-status:
  - off
autopostToMastodonshare-lastSuccessfullTootURL:
  - https://sc.sigmaris.info/@hughcb/101536503372712317
categories:
  - Rust

---
Wanting to compile a small program I&#8217;d written in Rust to run on my home router, I found [this guide][1] to cross compilation of Rust code. The router is a Netgear R7000 with an ARM processor, running FreshTomato, a distribution of Linux for ARM and MIPS architecture consumer routers. The top of that guide shows an example of installing the cross-compilation toolchain for ARM on Ubuntu, but it required some work to adapt to Mac OS High Sierra, my desktop environment.

The guide suggests [rustup][2] can be used to install extra cross compilation targets. I already have rustup which I&#8217;ve used to install Rust for Mac OS and keep it up-to-date, so that&#8217;s handy. So I ran &#8220;rustup target list&#8221; to list all the installable targets:

```
aarch64-apple-ios
aarch64-fuchsia
aarch64-linux-android
aarch64-pc-windows-msvc
aarch64-unknown-cloudabi
aarch64-unknown-linux-gnu
aarch64-unknown-linux-musl
arm-linux-androideabi
arm-unknown-linux-gnueabi
arm-unknown-linux-gnueabihf
arm-unknown-linux-musleabi
arm-unknown-linux-musleabihf
armebv7r-none-eabi
armebv7r-none-eabihf
armv5te-unknown-linux-gnueabi
armv5te-unknown-linux-musleabi
armv7-apple-ios
armv7-linux-androideabi
armv7-unknown-linux-gnueabihf
armv7-unknown-linux-musleabihf
armv7r-none-eabi
armv7r-none-eabihf
armv7s-apple-ios
asmjs-unknown-emscripten
i386-apple-ios
(many more x86, mips, powerpc and x86_64 targets)
```

That&#8217;s a lot of possible targets. It looks like in the ARM space, there&#8217;s AArch64, arm-unknown, armebv7r, armv5te and armv7(r?) architectures of various variants. So, let&#8217;s google to see what kind of CPU the router has.

According to [the OpenWRT wiki][3] it&#8217;s a Broadcom BCM4709A0. So, what kind of architecture is that? Googling for &#8220;BCM4709A0&#8221; brought me to [Wikidevi][4], which says it&#8217;s an ARM Cortex-A9. Looking at [Wikipedia][5] for the Cortex-A9 tells me:

  * It&#8217;s a 32-bit architecture, so not AArch64
  * It&#8217;s an ARMv7-A architecture

So I&#8217;d guess one of the armv7 targets is the best one. It&#8217;s probably not armv7-apple-ios or armv7-linux-androideabi, since this isn&#8217;t an iOS or Android OS. That leaves armv7-unknown-linux-gnueabihf, armv7-unknown-linux-musleabihf, armv7r-none-eabi and armv7r-none-eabihf. I know the router runs Linux, so let&#8217;s try the first two. I installed the armv7-unknown-linux-gnueabihf target with:

```
rustup target add armv7-unknown-linux-gnueabihf
```

OK, let&#8217;s try compiling a &#8220;hello world&#8221; Rust application with that target:

```
cargo build --target=armv7-unknown-linux-gnueabihf
```

That failed with a message &#8220;error: linking with cc failed: exit code: 1&#8221; and then a note showing the entire cc command, and a note saying:


```
= note: clang: warning: argument unused during compilation: '-pie' [-Wunused-command-line-argument]
           ld: unknown option: --as-needed
           clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

OK, so I guess this is clang giving that error. Clang is the native C compiler for Mac OS, but I expect it can&#8217;t link an ARM executable in the way Rust wants. So, it looks like we need a linker for ARM. Reading the [guide][1] seems to suggest that Rust doesn&#8217;t have its own linker for Linux targets &#8211; it uses the linker from a C toolchain, for example the GNU C compiler. So we need to install a C toolchain targeting ARM.

My first stop when looking to install open source tools on Mac OS is [Homebrew][6], and indeed there&#8217;s a formula on there for [arm-linux-gnueabihf-binutils][7] &#8211; it looks like that could be what we need to get a linker targeting ARM Linux. So let&#8217;s install that with:

```
brew install arm-linux-gnueabihf-binutils
```

That installs a set of tools named arm-linux-gnueabihf-addr2line, arm-linux-gnueabihf-ar and so on. I know the linker is normally invoked as &#8220;ld&#8221;, and cross-compilation toolchains by convention prefix their tool names with the target name, so the ARM Linux linker should be arm-linux-gnueabihf-ld. I know from the [guide][1] that this needs to go in ~/.cargo/config in a section like this:

```
[target.armv7-unknown-linux-gnueabihf]
linker = "arm-linux-gnueabihf-gcc"
```

But the Homebrew formula didn&#8217;t install arm-linux-gnueabihf-gcc &#8211; it only has arm-linux-gnueabihf-ld. Well, let&#8217;s try that instead, so the config is:

```
[target.armv7-unknown-linux-gnueabihf]
linker = "arm-linux-gnueabihf-ld"
```

OK, let&#8217;s try compiling again&#8230;

```
   Compiling rust-sandbox v0.1.0 (/Users/hugh/Source/rust-sandbox)

error: linking with `arm-linux-gnueabihf-ld` failed: exit code: 1
  |
  (...long command removed...)
  = note: arm-linux-gnueabihf-ld: cannot find -ldl
          arm-linux-gnueabihf-ld: cannot find -lrt
          arm-linux-gnueabihf-ld: cannot find -lpthread
          arm-linux-gnueabihf-ld: cannot find -lgcc_s
          arm-linux-gnueabihf-ld: cannot find -lc
          arm-linux-gnueabihf-ld: cannot find -lm
          arm-linux-gnueabihf-ld: cannot find -lrt
          arm-linux-gnueabihf-ld: cannot find -lpthread
          arm-linux-gnueabihf-ld: cannot find -lutil
          arm-linux-gnueabihf-ld: cannot find -lutil
```

This is more promising, but it looks like the linker can&#8217;t find all of those libraries to link with. Those look like parts of the GNU C library and other system libraries for Linux, which the Homebrew package arm-linux-gnueabihf-binutils doesn&#8217;t seem to include. These would normally be installed on a Linux system, but on Mac OS we don&#8217;t have them.

It seemed like I might need to install a more complete Linux toolchain that includes those libraries, but before trying that, let&#8217;s look at the other Rust target &#8211; armv7-unknown-linux-musleabihf. The &#8220;musl&#8221; in the name refers to the musl C library, a small C library that can be [statically linked with Rust programs][8] instead of the GNU C library. This sounds promising as it removes the need to link against libpthread, etc, which we had problems with earlier.

Let&#8217;s put the same linker configuration in ~/.cargo/config for the armv7-unknown-linux-musleabihf target:

```
[target.armv7-unknown-linux-musleabihf]
linker = "arm-linux-gnueabihf-ld"
```

And try compiling our Rust program with this target:

```
cargo build --target=armv7-unknown-linux-musleabihf
   Compiling rust-sandbox v0.1.0 (/Users/hugh/Source/rust-sandbox)
    Finished dev [unoptimized + debuginfo] target(s) in 1.12s
```

It built, so let&#8217;s copy the executable to the router:

```
scp target/armv7-unknown-linux-musleabihf/debug/rust-sandbox router:/tmp/
```

And then SSH on to the router and run it:

```
$ ssh router.sigmaris.info
 ========================================================
 Welcome to the Netgear R7000 [TomatoUSB]
 (output trimmed)
 ========================================================

root@router:/tmp/home/root# /tmp/rust-sandbox
Hello, world!
```

Great, it works! Using the musl C library and statically linking everything is somewhat less optimal than linking against the C library that&#8217;s already installed on Linux, as it means the built executable size is larger, but it&#8217;s good enough for a simple Rust program.

 [1]: https://github.com/japaric/rust-cross
 [2]: https://rustup.rs
 [3]: https://oldwiki.archive.openwrt.org/toh/netgear/r7000
 [4]: https://wikidevi.com/wiki/Broadcom
 [5]: https://en.wikipedia.org/wiki/ARM_Cortex-A9
 [6]: https://brew.sh
 [7]: https://formulae.brew.sh/formula/arm-linux-gnueabihf-binutils
 [8]: https://blog.rust-lang.org/2016/05/13/rustup.html#example-building-static-binaries-on-linux
