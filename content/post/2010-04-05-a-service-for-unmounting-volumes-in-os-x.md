---
title: A Service for unmounting volumes in OS X
author: sigmaris
type: post
date: 2010-04-05T00:13:47+00:00
url: /2010/04/a-service-for-unmounting-volumes-in-os-x/
categories:
  - Uncategorized

---
A little while ago I had a problem. My phone is a Sony Ericsson K800i, with 64MB of internal storage and a slot for Memory Stick expansion storage. I was using it as an MP3 player, and so had an 8GB memory stick in there to store MP3s.

When I connected it to my Mac in USB drive mode to transfer files, it appeared in the Finder as two storage devices, one for the internal storage and one for the memory stick. When I&#8217;d finished transferring files I would click Eject on the memory stick&#8217;s device to safely remove it. Then I&#8217;d do the same on the internal storage&#8217;s device, but this would eventually fail and report an I/O error. The phone&#8217;s screen would show that the USB connection had ended, but one of the devices would still show in the Finder. If I then unplugged the USB cable the Finder would tell me that data might have been lost since I didn&#8217;t eject the storage device properly.

I eventually found a workaround &#8211; go into the Disk Utility app, and Unmount (not Eject) one device, then Eject the other. The order didn&#8217;t seem to matter, as the Eject would cause both devices to disappear. However this required me to launch Disk Utility to do the unmounting every time I had to unplug the phone from the Mac.

I started to get fed up of the extra time and clicking involved, so I decided to write a single-function Service to do the unmounting. Check it out [here][1].

 [1]: {{< ref "/page/unmountservice.md" >}}
