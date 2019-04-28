---
title: Two-factor authentication with Mac OS X and OpenSC part 2
author: sigmaris
type: post
date: 2011-02-20T23:11:50+00:00
url: /2011/02/two-factor-authentication-with-mac-os-x-and-opensc-part-2/
categories:
  - mac
  - smartcard
tags:
  - encryption
  - mac
  - opensc
  - security
  - smartcard

---
This is the second part of the guide to smartcard-based authentication on Mac OS X. In this part of the guide, I&#8217;m going to assume that following Part 1, you have installed OpenSC, initialised your smartcard, and loaded or generated some certificates and private keys onto it. Now I&#8217;m going to show you how to use the card for actual authentication.

<!--more-->

### Smartcard as Keychain

The first step is to get it working with Mac OS X is to check that it shows up as a Keychain with the certificates you loaded on it. Open /Applications/Utilities/Keychain Access.app and look in the list of keychains at the top left. There should be an entry for your smartcard &#8211; if you didn&#8217;t give the smartcard a label when initialising it, the keychain will be named &#8216;OpenSC Card &#8230;&#8217;. If you click on the keychain in the list, you should see the contents include any certificates and keys that you loaded on the card. Make sure that any certificates that identify you, with associated private keys on the card, show up in the &#8216;My Certificates&#8217; category.

If the card doesn&#8217;t show up as a keychain, it means the OpenSC Tokend (the software component which communicates with the card on behalf of OS X) isn&#8217;t operating properly. Unfortunately the best way to debug this is to look at the log files in Console.app.

In the system.log file when the card reader is plugged in you should see the smart card reader (SmartcardCCID) start up:

```
com.apple.securityd[44]: /SourceCache/SmartcardCCID/SmartcardCCID-35253/ccid/ccid/src/ifdhandler.c:1323:init_driver() Driver version: 1.3.8
pcscd[6663]: Non-smartcard device launched pcscd [Vendor: 0X54C, Product: 0X155]
```

Then when the card is inserted into the reader (or immediately afterwards, if you are using a USB token with integrated card and reader), you should see messages similar to this in the secure.log file:

```
com.apple.SecurityServer[44]: Token reader ACS ACR 38U-CCID 00 00 inserted into system
com.apple.SecurityServer[44]: token inserted into reader ACS ACR 38U-CCID 00 00
com.apple.SecurityServer[44]: reader ACS ACR 38U-CCID 00 00 inserted token “OpenSC Card” (OpenSC3090241616010310) subservice 2 using driver com.apple.tokend.opensc
```

This shows that a ‘token’ (i.e. a smartcard) was inserted into the card reader, and it was recognised by the OpenSC Tokend.

### Login Authentication

To get Mac OS X to use this smartcard to authenticate you, it must have a certificate and accompanying private key already loaded onto it (see [part 1][1]). Now we must add an attribute to your user record in OS X containing the public key hash of the certificate. OS X will notice if a smartcard with the associated certificate and private key is inserted, and allow you to log in.

Adding the attribute can be done with a command-line tool named `sc_auth`. Insert the smartcard with the certificate you want to use, open up a terminal, and type in:

```
sc_auth hash
```

This should list the public key hashes and names of any identity certificates found in all your keychains, giving output similar to this:

```
DD5D693D420A9FEFDA979950142F8B592C869139 OpenSC Card (User PIN):Your Network ID Certificate
9A63B1932497A1D95967857FACD4A4B19A7C5226 com.apple.systemdefault
CCD99DBE1CE0D3962CA4D329BB5943EB83C78E68 localhost
BC944D344B2323615597B89DF836FEBF0177053C com.apple.kerberos.kdc
```

Ignore the com.apple&#8230; and localhost entries for now. The hash we want is the top one which relates to the certificate on your smartcard. It might also just be called ‘Private Key’. Copy your 40-character hash string from this row (the hexadecimal part before “OpenSC Card&#8230;&#8221;), and paste it into the following command:

```
sudo sc_auth accept -u username -h DD5D693D420A9FEFDA979950142F8B592C869139
```

Substitute your username for ‘username’ and your certificate hash value for the one above. sudo will ask for your password, then sc_auth will add an attribute to your user record identifying the certificate as one that is accepted for logging you in.

To test it, remove the smartcard, and log out. At the login window, insert the smartcard and wait a few seconds. The normal login window with a password box should change to showing a PIN prompt. Type in the smartcard’s PIN, and it should authenticate you using the associated private key on the smartcard, and log you in. You should also be able to authenticate yourself by typing in the PIN when performing an option that requires privileges (e.g. unlocking the padlock icon in System Preferences).

### Digitally Signing and Encrypting Email

If you have the OpenSC tokend working, and a valid email signing certificate on your smartcard, Mail.app should be able to digitally sign and encrypt email, using the <a title="Wikipedia page for S/MIME" href="http://en.wikipedia.org/wiki/S/MIME" target="_blank">S/MIME</a> standard, without any extra configuration. There are a few things to note, though:

* You need a valid (non-expired) certificate on the smartcard, with your email address in the emailAddress field.
* The email address on the cert must match your address as set up in your account in Mail.app (case sensitive).
* If you start Mail.app with no smartcard inserted, you may need to restart it to get the <a title="Sending signed and encrypted messages" href="http://docs.info.apple.com/article.html?path=Mail/4.0/en/10009.html" target="_blank">signing and encryption options</a> to appear.
* Your email signing certificate must be issued by a widely trusted CA (e.g. Thawte, Verisign, Comodo, etc) for it to show as ‘trusted’ in other people’s mail clients.
* To encrypt an email to someone, you must have their email certificate, as well as having you own. You can digitally sign emails to anyone, though. The easiest way to get someone else’s email certificate is to get them to send you a signed email.

 [1]: /blog/?p=97 "Two-factor authentication with Mac OS X and OpenSC, part 1"
