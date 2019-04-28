---
title: Make certbot Let’s Encrypt certificates readable by Debian ssl-cert group
author: sigmaris
type: post
date: 2019-01-05T12:09:15+00:00
url: /2019/01/make-certbot-lets-encrypt-certificates-readable-by-debian-ssl-cert-group/
autopostToMastodon-post-status:
  - off
autopostToMastodonshare-lastSuccessfullTootURL:
  - https://sc.sigmaris.info/@hughcb/101363907515834616
categories:
  - linux

---
On Debian, there&#8217;s a group named _ssl-cert_ which grants access to TLS certificates and private keys, so that services that don&#8217;t run as the root user can still use TLS certificates. For example, the PostgreSQL Debian package installs PostgreSQL to run as a user named _postgres_, which is a member of the _ssl-cert_ group, and so it can use certificates and private keys in **/etc/ssl**.

The certbot Let&#8217;s Encrypt client, by default, makes the certificates and private keys it installs only readable by the root user. There is an [open issue][1] against certbot, requesting that on Debian, certbot should follow the Debian standard of making the certificates and keys readable by the _ssl-cert_ group as well. In the meantime, until that issue is resolved, the ownership can be set by a post-hook which will be run by certbot after obtaining or renewing a certificate.

To do that, add this line to your certbot configuration file, i.e. **/etc/letsencrypt/cli.ini**:

```
post-hook = chmod 0640 /etc/letsencrypt/archive/*/privkey*.pem && chmod g+rx /etc/letsencrypt/live /etc/letsencrypt/archive && chown -R root:ssl-cert /etc/letsencrypt/live /etc/letsencrypt/archive
```

 [1]: https://github.com/certbot/certbot/issues/1425
