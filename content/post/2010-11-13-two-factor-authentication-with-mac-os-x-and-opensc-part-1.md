---
title: Two-factor authentication with Mac OS X and OpenSC part 1
author: sigmaris
type: post
date: 2010-11-13T22:59:27+00:00
url: /2010/11/two-factor-authentication-with-mac-os-x-and-opensc-part-1/
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
Interested in using a smartcard for secure two-factor authentication on OS X? What about E-mail signing and encryption, SSH key authentication, and more? All of these applications are possible, using the built-in smartcard support in OS X and open source software. What follows is the first part of a guide to using smartcards on OS X, using software from the <a title="OpenSC Project" href="http://www.opensc-project.org/" target="_blank">OpenSC Project</a>.

<!--more-->You&#8217;ll need:

  * The <a title="OpenSC Mac Installer" href="http://www.opensc-project.org/opensc/wiki/MacInstaller" target="_blank">Mac Installer Package</a> from OpenSC
  * A blank smartcard supported by OpenSC (see <a title="List of OpenSC supported hardware" href="http://www.opensc-project.org/opensc/wiki/SupportedHardware" target="_blank">list</a>)
  * A card reader with Mac OS X support (The best choice is a CCID compliant USB device, see <a title="CCID supported readers list" href="http://pcsclite.alioth.debian.org/section.html" target="_blank">list</a>)

I&#8217;m using a Feitian PKI card from <a title="gooze.eu website" href="http://www.gooze.eu/" target="_blank">gooze.eu</a> which is supported by the entersafe driver in OpenSC. Other good choices are the <a title="Aventra MyEID details" href="http://www.opensc-project.org/opensc/wiki/MyEID" target="_blank">Aventra MyEID</a> card, or a blank JavaCard which can be loaded with the <a title="MuscleCard applet" href="http://www.opensc-project.org/opensc/wiki/MuscleApplet" target="_blank">MUSCLE applet</a>. Please note that I&#8217;ve only tested this with the Feitian PKI card and an ACR-38U CCID compatible reader &#8211; YMMV with other combinations of cards and readers! The <a title="OpenSC project Wiki" href="http://www.opensc-project.org/opensc" target="_blank">OpenSC Wiki</a> provides useful information on initialising many different types of cards.

### Install OpenSC

Download the Mac Installer package mentioned above, and install the package contained within. This will install OpenSC to /Library/OpenSC, and also install a few other components which integrate OpenSC with Mac OS X. The most important of these is the Tokend (Token Daemon), a component which integrates your smartcard with the Keychain framework in OS X.

### Testing OpenSC

Open a Terminal window. Plug the card reader into your Mac, and enter the command

```
opensc-tool --list-readers
```

You should see your card reader shown in the list, like this:

```
Readers known about:
Nr.    Driver     Name
0      pcsc       CASTLES EZ100PU 00 00
```

Then, insert your blank smartcard into the reader, and enter the command (assuming you are using reader 0):

```
opensc-tool --reader 0 --atr
```

You should see a string of hex digits which identifies your card. Now, check that OpenSC recognises the card and can match it to a driver:

```
opensc-tool --reader 0 --name
```

should print a human-readable name for the card. For my Feitian PKI card it just prints &#8220;entersafe&#8221;.

### Initialising the PKCS#15 structure

If all these tests succeed, you can proceed to initialising the PKCS#15 structure on the card. For this we use the pkcs15-init command from OpenSC:

```
pkcs15-init -CT -p pkcs15+onepin --no-so-pin --pin yourpin --puk yourpuk --label "YourName"
```

The options here are:

* -C creates the PKCS#15 files.
* -T uses the default Transport Key (a key needed to access the card).
* -p pkcs15+onepin sets the card to use a single PIN for all operations.
* &#8212;no-so-pin tells the command we don&#8217;t want a Security Officer PIN.
* &#8212;pin yourpin specifies the PIN. Replace yourpin with whatever you want to use.
* &#8212;puk yourpuk specifies the PUK (Unblock code). Replace yourpuk with whatever you want to use.
* &#8212;label &#8220;YourName&#8221; gives the card a name which it&#8217;ll be displayed under in the Keychain and other applications.

We are only using one PIN here as the card will just be for personal use. We also don&#8217;t define a Security Officer PIN. The S.O. PIN is like an administrator password &#8211; it is used to protect the meta-data on the card including the PKCS#15 structure, in a situation where the person provisioning and issuing the card is not the same as the card&#8217;s end-user.

The PUK (Pin Unlock Key) is used to unblock the card if you have locked it due to too many incorrect PIN attempts. Make sure to define one as secure as possible and keep it safe in case you ever forget the PIN. To check that the command ran successfully, we can list the contents of the PKCS#15 structure on the card. This is done with the command:

```
pkcs15-tool --dump
```

This should show output something like this:

```
Using reader with a card: CASTLES EZ100PU 00 00
PKCS#15 Card [OpenSC Card]:
Version        : 1
Serial number  : 0143540243543568
Manufacturer ID: EnterSafe
Last update    : 20100423143625Z
Flags          : EID compliant

PIN [User PIN]
Com. Flags: 0x3
ID        : 01
Flags     : [0x30], initialized, needs-padding
Length    : min_len:4, max_len:16, stored_len:16
Pad char  : 0x00
Reference : 1
Type      : ascii-numeric
Path      : 3f005015
```

You can see that one PIN has been created, with an ID of 01.

### Adding keys

To actually use the card for authentication, there must exist keys for encryption and digital signature on the card. Pairs of RSA public/private keys are the most commonly used form. Both the private and public keys are generated or loaded onto the card. The public key may be read from the card, but the private key may not be read &#8211; it stays on the card. The private key can only be used to encrypt / sign data by sending the card the PIN and the data to be signed. By this mechanism, it is ensured that only the person holding the card, and knowing the PIN, can make use of the private key.

#### Option 1 &#8211; Generate a key pair on the card

This is one of the most secure options, as the private key is generated on the card and never leaves it. To generate a 2048bit RSA key pair, use the command:

```
pkcs15-init -G rsa/2048 -a 01 -u sign,decrypt
```

The options used here are:

* -G rsa/2048 to generate a 2048-bit RSA keypair.
* -a 01 to protect the key with auth ID 01 (the ID of the PIN you previously defined).
* -u sign,decrypt to allow both signing and decryption with the key.

A 2048-bit key is recommended, however some cards may only support 1024 bit keys. You may be asked for your PIN several times during the process, which could take some time. Once it is over, the output of pkcs15-tool &#8211;dump should show a &#8220;Private RSA Key&#8221; and &#8220;Public RSA Key&#8221;.

To make use of the key with Mac OS X, it needs to be associated with a X.509 certificate stored on the card. The certificate must be signed with the private key on the card. To accomplish this, we will use OpenSSL with the engine_pkcs11 component from OpenSC to generate a self-signed certificate.

First, start OpenSSL:

```
$ openssl
OpenSSL>
```

Now, load the PKCS#11 engine, with the correct PKCS#11 module from OpenSC:

```
OpenSSL> engine dynamic -pre SO_PATH:/Library/OpenSC/lib/engines/engine_pkcs11.so \
-pre ID:pkcs11 -pre LIST_ADD:1 -pre LOAD -pre MODULE_PATH:/Library/OpenSC/lib/pkcs11/onepin-opensc-pkcs11.so
(dynamic) Dynamic engine loading support
[Success]: SO_PATH:/Library/OpenSC/lib/engines/engine_pkcs11.so
[Success]: ID:pkcs11
[Success]: LIST_ADD:1
[Success]: LOAD
[Success]: MODULE_PATH:/Library/OpenSC/lib/pkcs11/onepin-opensc-pkcs11.so
Loaded: (pkcs11) pkcs11 engine
```

Now the engine is loaded, tell OpenSSL to generate a self-signed certificate:

```
OpenSSL> req -engine pkcs11 -new -key id_45 -keyform engine -x509 -out cert.pem -text -days 365
```

This requests a self-signed certificate, with the private key id_45 (If the private key you generated has a different ID number, shown in pkcs15-tool &#8211;dump, use that instead of 45). We also ask for a validity period of 365 days (1 year). You will be asked for the smartcard&#8217;s PIN, then some information to put in the certificate such as your locality, name and e-mail address. This information can be left blank if you wish. After entering this information, the certificate will be written to the file cert.pem.

Finally, load the certificate onto the card with the command

```
pkcs15-init -X cert.pem --auth-id 01 --id 45 --format pem
```

After this is done, the output of pkcs15-tool &#8211;dump should show both the private and public keys, and an X.509 certificate, all with the same ID.


#### Option 2 &#8211; Load a certificate and private key onto the card

This can be more useful if you already have a certificate from a CA, for example the free e-mail signing certs that are issued by <a title="InstantSSL free e-mail certificate" href="http://www.instantssl.com/ssl-certificate-products/free-email-certificate.html" target="_blank">instantssl.com</a>, or a certificate issued by your organization. Assuming your certificate and key are packaged in a PKCS#12 format file, use the following command to import them onto the card:

```
pkcs15-init -S cert.p12 --format PKCS12 --auth-id 01
```

This will store the cert and private key on the card and associate them together.

#### Option 3 &#8211; Use the PKCS#11 plugin in Firefox to get a certificate from a CA

This method generates the key pair on the card, like option 1, for added security. It then uses the keys to make a certificate signing request with a CA, and when the CA sends back the signed certificate, it installs the certificate on the card. It will only work if the CA uses a web-based issuing process, using the `<keygen>` element to generate the key in the browser and submit a signing request.

First you need to add the OpenSC PKCS#11 plugin to Firefox. PKCS#11 is a standard for plugins which communicate with security devices and can use the devices to perform encryption-related operations. Firefox can make use of devices with PKCS#11-compatible plugins, and luckily OpenSC provides such a plugin which will work with all types of card supported by OpenSC.

Open the Firefox Preferences, and in the Advanced tab select Encryption. Click &#8220;Security Devices&#8221; and you should see the following window:

<a href="/blog/uploads/2010/11/ffx_securitydevs.png"><img class="size-medium wp-image-113 aligncenter" title="Firefox Security Devices" src="/blog/uploads/2010/11/ffx_securitydevs-300x208.png" alt="Firefox Security Devices" width="300" height="208" srcset="/blog/uploads/2010/11/ffx_securitydevs-300x208.png 300w, /blog/uploads/2010/11/ffx_securitydevs.png 654w" sizes="(max-width: 300px) 100vw, 300px" /></a>

Click &#8220;Load&#8221; and enter &#8220;OpenSC&#8221; for the module name. Click Browse for the module filename, and choose:

```
/Library/OpenSC/lib/onepin-opensc-pkcs11.so
```

for the path. Click OK and you should see a new OpenSC module in the list, with some slots under it. If your reader and card are plugged in, one of the slots should display your card. If it shows up, you know that PKCS#11 is working OK.

Now click OK on the Device Manager window, and close the Preferences window. Go to the CA&#8217;s site (for example <a title="InstantSSL" href="http://www.instantssl.com/ssl-certificate-products/free-email-certificate.html" target="_blank">InstantSSL / Comodo</a>) and follow their procedures to get a certificate. The CA will first ask your browser to generate a key, at this point Firefox should ask if you want to generate the key using your PKCS#11 device. Select your card and generate the key (you will be prompted for your PIN). The CA will then give you more steps to follow to collect the signed certificate &#8211; normally they will send you a link by e-mail after generating it. Visit the link to collect the certificate  using Firefox, with your card and reader plugged in, and Firefox should detect that the certificate is associated with your key on the smartcard, and offer to also install it on the card.

After installing the certificate, it should show up in the &#8220;View Certificates&#8221; window in the Advanced Encryption preferences in Firefox.

### Using the keys and certificates

The guide so far has shown how to install OpenSC and initialise your smartcard, but how do you use the card once all this is done? That will be the subject of the second part of this guide, which will be posted soon.
