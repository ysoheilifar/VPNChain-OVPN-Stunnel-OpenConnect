# VPNChain OVPN, Stunnel and OpenConnect

### VPN Chain
The earliest mention I can find of VPN chains is a [2010 article](https://secure-computing.net/wiki/index.php/OpenVPN/VpnChains) by Eric Crist. That article envisaged a literal chain, in which one client connects to a server, which in turn connects to a further server, and on. It did not give any practical details.

The interest in VPN chains since then has been more in tunneling one connection through another. In particular, the question of how to build a tunnel through a tunnel was raised in a [2011 forum thread](https://forums.openvpn.net/viewtopic.php?t=7483) started by Bebop. A finished set of bash scripts was posted on [SourceForge](https://sourceforge.net/p/vpnchains/wiki/Home/) in 2012 by br41n. In 2017, the scripts were added to [GitHub](https://github.com/bitnom/VPN-Chain) by TensorTom. These inspired Mirimir to create an alternative set of [bash scripts](https://github.com/mirimir/vpnchains) in 2019.

A VPN chain disguises your destination from your ISP and VPN1, and disguises your origin from VPN2 and your final destination website. If your goal is anonymity, you will likely use commercial VPN services who accept anonymous payment. However, for demonstration purposes we will build our own VPN servers from scratch.

### OpenVPN + Stunnel + Openconnect
People in not-free countries often have a problem with OpenVPN connections being blocked by government censors. This article describes one possible solution. OpenVPN is tunneled through Stunnel, thus resembling a TLS connection on port 443. Whether or not this gets through Deep Packet Inspection (DPI) depends on the sophistication of the DPI. It may work in some countries but not in others. We include server name indicator (SNI) in the TLS to make the connection look a bit more like a real HTTPS connection.
