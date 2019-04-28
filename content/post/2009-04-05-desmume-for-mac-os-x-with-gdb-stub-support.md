---
title: DesMuME for Mac OS X with GDB stub support
author: sigmaris
type: post
date: 2009-04-06T04:00:11+00:00
url: /2009/04/desmume-for-mac-os-x-with-gdb-stub-support/
categories:
  - development
  - mac
  - nds

---
I&#8217;ve built a Mac (Intel) binary of DesMuME, from the latest SVN code, with a patch to enable masscat&#8217;s GDB stub. With it you can load a homebrew rom, connect to DesMuME with the copy of GDB that&#8217;s provided with devkitARM, and start debugging your homebrew code while it&#8217;s running in the emulator. For more details check out [this post][1] on the official forums.

The binary can be found [here][2], and the modified parts of the source code can be downloaded [here][3]. Please let me know if you find any bugs related to using the GDB stub &#8211; I&#8217;ve tested it a bit and most features seem to work, but this is the first time I&#8217;ve worked on the DesMuME code and I may have overlooked something. I take no responsibility for bugs in the unmodified Mac version of DesMuME though 😉

### How to use it:

Currently the only method of specifying the debugger ports to use is on the command line. So, open up Terminal.app and run DesMuME from there, like so:

```
orange:~ sigmaris$ /path/to/DeSmuME.app/Contents/MacOS/DeSmuME -arm9gdb 20000
```

Note the single dash before the argument. This will start the ARM9 stub listening on port 20000. You can also use `-arm7gdb <port>` to start the ARM7 stub. You can omit either of the arm9gdb or arm7gdb arguments and it won&#8217;t start the respective GDB stubs at all. If startup was successful you should see log messages like this on the console:

```
2009-04-05 22:32:41.896 DeSmuME[29404:10b] Using ARM9 GDB port 20000
```

Then go to the DesMuME window, set up a FAT image if necessary, and load your homebrew ROM. You&#8217;ll notice it doesn&#8217;t start immediately but just shows a white screen. It is waiting for GDB to connect, so go ahead and start it up (I assume you have devkitPRO installed in /usr/local)

```
orange:~ sigmaris$ /usr/local/devkitPRO/devkitARM/bin/arm-eabi-gdb homebrew.elf
```

You should point gdb to the compiled ELF file of the homebrew ROM that you loaded earlier. You should see the (gdb) prompt, now tell GDB to connect to the DesMuME stub:

```
(gdb) target remote :20000
Remote debugging using :20000
0x02000000 in _start ()
(gdb)
```

If you see the above output, you&#8217;re ready to start debugging. For example, set a breakpoint on a function that you use in your homebrew program, and then enter &#8216;cont&#8217; to tell DesMuME to continue running the program. You should see your program run up to the breakpoint and then stop, and GDB will print a message saying it encountered the breakpoint. You can now examine the state of local variables, print a backtrace, or step line-by-line through your code.

Hopefully this will be useful for some homebrew DS developers on the Mac. Unfortunately, even with the GDB stub in place, DesMuME doesn&#8217;t catch many of the errors that would trip you up on a real DS like writes to invalid memory and other similar errors. But being able to jump in anywhere and examine the running state of your code is a step forward from just using tons of iprintf() calls 😉

 [1]: http://forums.desmume.org/viewtopic.php?id=85 "Desmume + GDB debugger stub"
 [2]: /files/desmume-gdbstub-svn.zip "DesMuMe Mac binary with GDB stub"
 [3]: /files/desmume-gdbstub-svn-src.zip "DesMuMe Mac source patched to use GDB stub"
