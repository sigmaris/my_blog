---
title: emitSMS plugin for Mac OS X Address Book.app
author: sigmaris
type: post
date: 2009-09-14T16:16:27+00:00
url: /2009/09/emitsms-plugin-for-mac-os-x-address-book-app/
categories:
  - development
  - mac

---
In the distant past, the Address Book app in Mac OS X Tiger could send mobile SMS messages directly from within the app, if you paired your mobile phone with your Mac via Bluetooth. Along came Leopard, and the feature mysteriously vanished without trace or explanation, and hasn&#8217;t reappeared since. Missing the feature, I found a roundabout replacement in the [emitSMS][1] dashboard widget. It offers SMS sending via Bluetooth and can also search the Address Book for phone numbers. Having seen that the [source code][2] for emitSMS was released, I adapted the backend into a plugin for Address Book.app to provide the missing former functionality.<!--more-->

[Download][3], unzip and place the plugin in /Library/Address Book Plug-Ins/ and restart Address Book. You should then be able to click on a phone number on a person&#8217;s card and select &#8220;Send SMS via Bluetooth&#8221; to send them a SMS.

[<img class="aligncenter size-medium wp-image-44" title="Screen shot of emitSMS Address Book plugin" src="/blog/uploads/2009/09/Screen-shot-2009-09-14-at-16.05.47-300x226.png" alt="Screen shot of emitSMS Address Book plugin" width="300" height="226" srcset="/blog/uploads/2009/09/Screen-shot-2009-09-14-at-16.05.47-300x226.png 300w, /blog/uploads/2009/09/Screen-shot-2009-09-14-at-16.05.47.png 994w" sizes="(max-width: 300px) 100vw, 300px" />][4]The <a title="emitSMS Address Book plugin source code" href="https://github.com/sigmaris/AddressBookSMS" target="_blank">source code</a> is also available, under the same MIT license as the original emitSMS source code.

### Notes

The plugin should be compatible with Address Book in Leopard and Snow Leopard.

<span style="text-decoration: line-through;">To use the plugin (or the emitSMS widget, in fact) you need to set up a virtual serial port over Bluetooth to your phone. This will normally be set up automatically by OS X when you pair your phone with your Mac, but the serial ports can be edited in the Bluetooth panel in System Preferences if necessary.</span> (edit: No longer necessary in the latest version, all you need to do is pair your phone with your Mac).

After you select a port to use in the pop-up menu, it will test the port for SMS sending capabilities. The port will only be usable if the test succeeds. Some phones seem to be a little flaky when communicating via Bluetooth and require the test to be run a few times before it can establish a connection successfully. If it fails initially, try clicking on the port again.

If &#8216;Long Messages&#8217; is not enabled your messages will be limited to 160 characters (or 70 characters if you use symbols outside the standard GSM set, e.g. ^ ). Not all phones support the sending of long messages (actually splitting the message into several SMSs). Additionally, not all phones support requesting delivery receipts.

In general, if your phone works with the emitSMS dashboard widget, it should work with this plugin as the same underlying method is used to send the SMSs.

 [1]: http://algoritmer.dk/widget/ "emitSMS widget homepage"
 [2]: http://algoritmer.dk/widget/develop.php "emitSMS development page"
 [3]: /files/emitSMSAddressBookPlugin.bundle.zip "emitSMS Address Book plugin binary"
 [4]: /blog/uploads/2009/09/Screen-shot-2009-09-14-at-16.05.47.png
