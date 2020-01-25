---
title: Home IPv6 Tunnel
author: sigmaris
type: post
date: 2012-06-09T17:34:27+00:00
url: /2012/06/home-ipv6-tunnel/
categories:
  - Uncategorized
tags:
  - dd-wrt
  - firewall
  - ipv6

---
The news of [World IPv6 Launch Day][1] last week prompted me to properly set up IPv6 for my home network. Unfortunately my ISP doesn&#8217;t offer native IPv6 connectivity — not many consumer ISPs do — but fortunately there are free services which will provide an IPv6 &#8216;tunnel&#8217; over the IPv4 internet, to the wider IPv6 world. I signed up to Hurricane Electric&#8217;s service at [tunnelbroker.net][2] and was soon up and running. Hurricane Electric will issue you a /64 block of IPv6 addresses, which you can allocate as you see fit. You need to set up one system to handle your end of the tunnel, and route all traffic destined for the wider IPv6 internet over the tunnel. I already had a Linux server running that was handling the local end, but since I&#8217;ve recently acquired an Asus RT-N16 router running [DD-WRT][3], I decided to enable IPv6 support on it and use it as the tunnel endpoint, so it can serve as the default gateway for both IPv4 and IPv6 on my LAN.

To do this you need to be running one of the DD-WRT builds with IPv6 support, I am using the &#8220;mega&#8221; build which includes pretty much everything. As well as enabling IPv6 support in the DD-WRT admin web interface, you need to set up a custom script to bring up the tunnel when the router starts up. The script I used is below &#8211; you need to replace the following:

`(userid)`
:   the User ID shown on the tunnelbroker.net page when you log in

`(md5password)`
:   the MD5 hash of your tunnelbroker.net password

`(tunnelid)`
:   the Tunnel ID of your tunnel

`(remotev4)`
:   the IPv4 address of the remote end

`(localv6)`
:   the IPv6 address of the local end

`(lanv6)`
:   one IPv6 address, out of your routed IPv6 /64, allocation that you want to use for your router on your LAN

```
insmod ipv6
WANIP=$(nvram get wan_ipaddr);
w<strong></strong>get -O - 'https://ipv4.tunnelbroker.net/ipv4_end.php?ipv4b=AUTO&user_id=(userid)&pass=(md5password)&tunnel_id=(tunnelid)'
ip tunnel add he-ipv6 mode sit remote (remotev4) local $WANIP ttl 255
ip link set he-ipv6 up
ip -6 addr add (localv6) dev he-ipv6
ip -6 addr add (lanv6) dev br0
ip -6 route add ::/0 dev he-ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
radvd -C /tmp/radvd.conf
```

This image shows where to find some of the information in your tunnelbroker.net page:

[<img class="aligncenter size-medium wp-image-183" title="tunnel details" src="/blog/uploads/2012/06/tunneldetails-300x249.png" alt="" width="300" height="249" srcset="/blog/uploads/2012/06/tunneldetails-300x249.png 300w, /blog/uploads/2012/06/tunneldetails.png 592w" sizes="(max-width: 300px) 100vw, 300px" />][4]

The setup script needs to be saved, as a custom startup script, in the Administration -) Commands section of the DD-WRT web interface.

I had also enabled [radvd][5] in the DD-WRT web interface to advertise the gateway to the wider IPv6 world on my LAN, but for me it failed to start on boot, so I added the `radvd -C /tmp/radvd.conf` line to make sure it starts after the tunnel is configured. The configuration file used for `radvd` is below, replace `(routedv6)` with your routed IPv6 /64 allocation, including the /64, and paste it into the box for `radvd` config in the DD-WRT web interface:

```
interface br0
{
   AdvSendAdvert on;
   prefix (routedv6)
   {
       AdvOnLink on;
       AdvAutonomous on;
   };
};
```

This setup means that on the other computers on the LAN (all Macs), I can set &#8220;Configure IPv6: Automatically&#8221; in the Network Preferences and IPv6 connectivity just works. The other machines on the LAN will configure themselves based on the information `radvd` sends out, using [stateless autoconfiguration][6]. However, this ease of use comes with a security risk&#8230;

<!--more-->We are used to having devices on a home network behind a home router, plugged into the DSL or Cable modem. The router normally does NAT to allow all the computers on the LAN to use a single IPv4 address that&#8217;s assigned by our ISP, and includes a simple firewall. Devices on the LAN have private IPs (e.g. in the 192.168.0.0/16 range) and are by default not reachable from the wider Internet, unless you specifically forward ports on your router to them. However with the advent of IPv6 this changes somewhat. As I mentioned above, with IPv6 connectivity comes a /64 block of routable IPv6 addresses to assign to devices on the LAN &#8211; each of these is fully reachable from the outside Internet. And if you&#8217;ve set up the system hosting the tunnel endpoint as an IPv6 router, it will happily send packets between anyone on the Internet and devices on your LAN. This is generally a Bad Thing, as we might be running all kinds of services like file sharing or VNC on our home systems that we don&#8217;t want (or need) exposed to the outside world. What we need is a firewall which works without NAT, allowing each device to have its own routable IPv6 address while protecting it from intrusion.

There are two options; either run a firewall on each machine on the LAN individually, or only run a firewall on the gateway and filter traffic at the ingress point to the LAN. I went with the latter option, since it only requires configuring one system instead of several, and I&#8217;m more familiar with the Linux `iptables` firewall system than the Mac OS X `pf` firewall.

Unfortunately while DD-WRT has basic IPv6 support, it doesn&#8217;t include the necessary kernel modules or userspace tools for setting up an IPv6 firewall. I had to download the kernel modules and ip6tables packages, following instructions [here][7] and install them to the `/jffs` partition on the router with `ipkg` (you also have to enable JFFS2 support on the router for this to be possible).

Once all this is installed, another script is necessary to start and configure the firewall. I used the following:

```bash
#!/bin/sh
export IP6TABLES_LIB_DIR=/jffs/usr/lib/iptables
export PATH=$PATH:/jffs/usr/sbin
insmod /jffs/lib/modules/2.6.24.111/ipv6.ko
insmod /jffs/lib/modules/2.6.24.111/ip6_tables.ko
insmod /jffs/lib/modules/2.6.24.111/ip6table_filter.ko
insmod /jffs/lib/modules/2.6.24.111/ip6table_mangle.ko
insmod /jffs/lib/modules/2.6.24.111/nf_conntrack_ipv6.ko
insmod /jffs/lib/modules/2.6.24.111/tunnel6.ko
insmod /jffs/lib/modules/2.6.24.111/ip6t_ah.ko
insmod /jffs/lib/modules/2.6.24.111/ip6t_owner.ko
insmod /jffs/lib/modules/2.6.24.111/ip6t_eui64.ko
insmod /jffs/lib/modules/2.6.24.111/ip6t_rt.ko
insmod /jffs/lib/modules/2.6.24.111/ip6t_frag.ko
insmod /jffs/lib/modules/2.6.24.111/ip6t_hbh.ko
insmod /jffs/lib/modules/2.6.24.111/ip6t_ipv6header.ko
insmod /jffs/lib/modules/2.6.24.111/ip6t_mh.ko
insmod /jffs/lib/modules/2.6.24.111/ip6t_LOG.ko
insmod /jffs/lib/modules/2.6.24.111/ip6t_HL.ko

#### BEGIN FIREWALL RULES ####
WAN_IF=he-ipv6
LAN_IF=br0

#flush tables
ip6tables -F

#define policy
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT ACCEPT

# Input to the router
# Allow all loopback traffic
ip6tables -A INPUT -i lo -j ACCEPT

#Allow unrestricted access on internal network
ip6tables -A INPUT -i $LAN_IF -j ACCEPT

#Allow traffic related to outgoing connections
ip6tables -A INPUT -i $WAN_IF -m state --state RELATED,ESTABLISHED -j ACCEPT

# for multicast ping replies from link-local addresses (these don't have an
# associated connection and would otherwise be marked INVALID)
ip6tables -A INPUT -p icmpv6 --icmpv6-type echo-reply -s fe80::/10 -j ACCEPT

# Allow some useful ICMPv6 messages
ip6tables -A INPUT -p icmpv6 --icmpv6-type destination-unreachable -j ACCEPT
ip6tables -A INPUT -p icmpv6 --icmpv6-type packet-too-big -j ACCEPT
ip6tables -A INPUT -p icmpv6 --icmpv6-type time-exceeded -j ACCEPT
ip6tables -A INPUT -p icmpv6 --icmpv6-type parameter-problem -j ACCEPT
ip6tables -A INPUT -p icmpv6 --icmpv6-type echo-request -j ACCEPT
ip6tables -A INPUT -p icmpv6 --icmpv6-type echo-reply -j ACCEPT

# Forwarding through from the internal network
# Allow unrestricted access out from the internal network
ip6tables -A FORWARD -i $LAN_IF -j ACCEPT

# Allow some useful ICMPv6 messages
ip6tables -A FORWARD -p icmpv6 --icmpv6-type destination-unreachable -j ACCEPT
ip6tables -A FORWARD -p icmpv6 --icmpv6-type packet-too-big -j ACCEPT
ip6tables -A FORWARD -p icmpv6 --icmpv6-type time-exceeded -j ACCEPT
ip6tables -A FORWARD -p icmpv6 --icmpv6-type parameter-problem -j ACCEPT
ip6tables -A FORWARD -p icmpv6 --icmpv6-type echo-request -j ACCEPT
ip6tables -A FORWARD -p icmpv6 --icmpv6-type echo-reply -j ACCEPT

#Allow traffic related to outgoing connections
ip6tables -A FORWARD -i $WAN_IF -m state --state RELATED,ESTABLISHED -j ACCEPT

# allow SSH and HTTP(S) dport in from the Internet
ip6tables -A FORWARD -s 2000::/3 -i $WAN_IF -p tcp -m multiport --dports 22,80,443 -j ACCEPT
```

This script needs to be saved as a Firewall script, again in the Administration -) Commands section of DD-WRT&#8217;s web interface. This is a fairly simple setup which allows all LAN and outgoing traffic, but blocks all incoming traffic from the internet, to any computer on the LAN, other than some ICMPv6 messages and traffic destined for SSH, HTTP and HTTPS ports. There are services running on some machines on the LAN on these ports that need to be reachable from the outside world; if you don&#8217;t need this for your network then remove the last rule. You can also add rules like

```
ip6tables -A FORWARD -s 2000::/3 -d (lan address) -i $WAN_IF -p tcp -m multiport --dports 5269,5222,64738 -j ACCEPT
```

to allow traffic on certain ports through only to one machine on your LAN.

I can now run an IPv6 port scan (for example [this one][8]) against any machine in my network and see only the necessary ports open, and traffic to all others being dropped. I can also check out various [cool IPv6 stuff][9] on the internet, get my IPv6 badge:[<img class="aligncenter" title="IPv6 Certification Badge for sigmaris" src="http://ipv6.he.net/certification/create_badge.php?pass_name=sigmaris&badge=3" alt="" width="229" height="137" />][10]

&#8230;and be content that all my traffic to and from www.google.com and www.yahoo.com, among [others][11], is now going via IPv6 :).

 [1]: http://www.worldipv6launch.org "World IPv6 Launch Day"
 [2]: http://tunnelbroker.net "Hurricane Electric Tunnel Broker"
 [3]: http://www.dd-wrt.com/ "DD-WRT open source router firmware"
 [4]: /blog/uploads/2012/06/tunneldetails.png
 [5]: http://www.litech.org/radvd/ "Routing Advertisement Daemon"
 [6]: http://tools.ietf.org/html/rfc4862 "IPv6 Stateless Address Autoconfiguration"
 [7]: http://www.dd-wrt.com/wiki/index.php/IPv6#ip6tables_for_K26_big_images "DD-WRT IPv6 Wiki page"
 [8]: http://ipv6.chappell-family.com/ipv6tcptest/ "IPv6 port scanner"
 [9]: http://www.sixxs.net/misc/coolstuff/ "Cool IPv6 Stuff"
 [10]: http://ipv6.he.net/certification/scoresheet.php?pass_name=sigmaris
 [11]: http://www.worldipv6launch.org/participants/?q=1 "IPv6 Launch Day participants"
