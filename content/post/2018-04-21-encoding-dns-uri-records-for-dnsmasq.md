---
title: Encoding DNS URI records for DNSMASQ
author: sigmaris
type: post
date: 2018-04-21T11:42:08+00:00
url: /2018/04/encoding-dns-uri-records-for-dnsmasq/
categories:
  - Uncategorized

---
[Dnsmasq][1] can be configured to add various types of records like SRV, PTR, and NAPTR to its internal DNS server by [various directives][2] in its configuration file. But what if there&#8217;s a less common type of DNS record that you want to serve, which dnsmasq doesn&#8217;t have a specific configuration directive to handle?

Handily, dnsmasq also supports serving arbitrary DNS resource records using the **dns-rr** option. However you have to supply the binary value of the response encoded in hexadecimal. Here&#8217;s an example of how to do this for a URI record with Python. The URI record type is described in [RFC 7553][3] which describes the binary value of the response (&#8220;wire format&#8221;) as:

> The RDATA for a URI RR consists of a 2-octet Priority field, a 2-octet Weight field, and a variable-length Target field.
>
> Priority and Weight are unsigned integers in network byte order.
>
> The remaining data in the RDATA contains the Target field. The Target field contains the URI as a sequence of octets (without the enclosing double-quote characters used in the presentation format).

So, we need to encode the priority as 2 bytes, then the weight as 2 bytes, then the URI itself. We can use Python&#8217;s [struct][4] module for encoding the integers, and the [binascii][5] module to encode the strings as hex:

```
import binascii
import struct
record_name = b'_something.example.com'
record_type = b'256'  # Assigned type number for URI records
priority = 10
weight = 5
value = b'http://www.example.com/'
print(b','.join((
    b'dns-rr=' + record_name,
    record_type,
    # The ! here uses network byte order, followed by two 'H's for unsigned 2-byte values.
    binascii.hexlify(struct.pack('!HH', priority, weight))
    + binascii.hexlify(value)
)).decode())
```

This will output:

```
dns-rr=_something.example.com,256,000a0005687474703a2f2f7777772e6578616d706c652e636f6d2f
```

which can be copied straight into dnsmasq&#8217;s configuration file.

 [1]: http://www.thekelleys.org.uk/dnsmasq/doc.html
 [2]: http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
 [3]: https://tools.ietf.org/html/rfc7553
 [4]: https://docs.python.org/3/library/struct.html#print
 [5]: https://docs.python.org/3/library/binascii.html#binascii.b2a_hex
