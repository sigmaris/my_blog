---
title: Address Book SMS Plugin
author: sigmaris
type: page
date: 2009-12-09T15:56:48+00:00

---
In the distant past, the Address Book app in Mac OS X Tiger could send mobile SMS messages directly from within the app, if you paired your mobile phone with your Mac via Bluetooth. Along came Leopard, and the feature mysteriously vanished without trace or explanation, and hasn’t reappeared since. Missing the feature, I found a roundabout replacement in the <a title="emitSMS widget homepage" href="http://algoritmer.dk/widget/">emitSMS</a> dashboard widget. It offers SMS sending via Bluetooth and can also search the Address Book for phone numbers. Having seen that the <a title="emitSMS development page" href="http://algoritmer.dk/widget/develop.php">source code</a> for emitSMS was released, I adapted the backend into a plugin for Address Book.app to provide the missing former functionality.

The latest version is v3, which has a few bugs fixed, in particular the one which caused it to hang after sending an SMS on some phones. It also now uses native Mac OS X methods to communicate with the phone, rather than an emulated serial port.

[Download][1], unzip and place the plugin in /Library/Address Book Plug-Ins/ and restart Address Book. You should then be able to click on a phone number on a person’s card and select “Send SMS via Bluetooth” to send them a SMS.

<a href="/blog/uploads/2009/09/Screen-shot-2009-09-14-at-16.05.47.png"><img style="max-width: 100%; display: block; margin-left: auto; margin-right: auto; padding: 0px; border: initial none initial;" title="Screen shot of emitSMS Address Book plugin" src="/blog/uploads/2009/09/Screen-shot-2009-09-14-at-16.05.47-300x226.png" alt="Screen shot of emitSMS Address Book plugin" width="300" height="226" /></a>The <a title="emitSMS Address Book plugin source code" href="https://github.com/sigmaris/AddressBookSMS" target="_blank">source code</a> is also available, under the same MIT license as the original emitSMS source code.

### Notes

The plugin should be compatible with Address Book in Leopard and Snow Leopard.

To use the plugin, you must first pair your phone with your Mac, by using the Bluetooth Setup Assistant. This assistant can be accessed by clicking the &#8216;plus&#8217; button in the Bluetooth System Preferences panel.

After you select a port to use in the pop-up menu, it will test the port for SMS sending capabilities. The port will only be usable if the test succeeds. Some phones seem to be a little flaky when communicating via Bluetooth and require the test to be run a few times before it can establish a connection successfully. If it fails initially, try clicking on the port again.

If ‘Long Messages’ is not enabled your messages will be limited to 160 characters (or 70 characters if you use symbols outside the standard GSM set, e.g. ^ ). Not all phones support the sending of long messages (actually splitting the message into several SMSs). Additionally, not all phones support requesting delivery receipts.

In general, if your phone works with the emitSMS dashboard widget, it should work with this plugin as the same underlying method is used to send the SMSs.

### Debug Version

If the plugin doesn&#8217;t work with your phone, replace the installed version with the debug version from [here][2]. Then try to send SMSes using the plugin. A log file, ABSMSPlugin.log, should be created in your home directory; send me the log file and I&#8217;ll try to add support or figure out the problem.

 [1]: /files/emitSMSAddressBookPlugin.bundle.zip "emitSMS Address Book plugin binary"
 [2]: /files/emitSMSAddressBookPlugin.bundle.debug.zip "emitSMS Address Book plugin debug version binary"
