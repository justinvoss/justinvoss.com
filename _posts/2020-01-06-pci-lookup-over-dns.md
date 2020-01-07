---
layout: post
title: PCI Lookup Over DNS
blurb: "(Ab)using DNS for things other than domain names."
guid: http://justinvoss.com/2020/01/06/pci-lookup-over-dns
---

Here's something neat I found out about today: it's possible to look up PCI databse information over DNS!

For example, if you're poking around a new machine and find a device with vendor ID `0x8086` and don't know who that is? Query for `TXT` records on `<vendor>.pci.id.icw.cz` like so:

```
$ dig 8086.pci.id.ucw.cz TXT +short
"i=Intel Corporation"
```

You can also get the name of a specific device by adding the device ID as another sub-domain, like `<device>.<vendor>.pci.id.icw.cz`. For example, if you had a device with vendor ID `0x8086` and device ID `0x101a`:

```
$ dig 101a.8086.pci.id.ucw.cz TXT +short
"i=82547EI Gigabit Ethernet Controller (Mobile)"
```

There are several more kinds of queries you can make; the source to [PCI Utilities][0], specifically the function [`pci_id_net_lookup()`][1] reveals how to build the appropriate 'domain name' to query.

[0]: https://github.com/gittup/pciutils
[1]: https://github.com/gittup/pciutils/blob/eacbf39d6a7a4b1d3a4399763352f78aa62996cb/lib/names-net.c#L150
