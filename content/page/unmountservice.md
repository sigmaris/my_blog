---
title: UnmountService
author: sigmaris
type: page
date: 2010-04-05T00:11:42+00:00

---
Services are a means in Mac OS X for the user to pass small pieces of data out of one application to another. The pieces of data may be snippets of text, images or files. Applications can publish Services that accept certain types of data, and these Services can be passed data out of almost any other Mac application.

In Snow Leopard, the role of Services has been expanded somewhat; they can now be accessed through the context menu of items they support. This means I can right-click on a file in the Finder, and get a context menu option &#8220;Send File To Bluetooth Device&#8221; which is a Service which can be sent files, published by the Bluetooth File Exchange utility. This application does the same kind of thing &#8211; it publishes a Service which can be sent volumes and attempts to unmount them.

You can [download][1] the service, unzip, and place in your /Library/Services folder. Finder should pick it up and then, when you right-click on a volume&#8217;s icon on the Desktop, you should see an &#8220;Unmount&#8221; option in the context menu. The [source code][2] can also be downloaded, it is pretty straightforward and could provide an example for developers of other simple services.

 [1]: /files/UnmountService.service.zip
 [2]: /files/UnmountService.src.zip
