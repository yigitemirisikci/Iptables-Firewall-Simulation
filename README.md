# Iptables Firewall Project

## Introduction

This project's goal was to create a simulated network environment with a custom iptables firewall. The setup required the establishment of controlled network communication between different namespaces, simulating client-server interactions, and internet access management.

## Project Overview

### Objectives

- To establish a network with four distinct namespaces: `client1`, `client2`, `server`, and `firewall`.
- To create virtual Ethernet connections for network communication.
- To host a sample HTTP service within the `server` namespace.
- To manage traffic flow with iptables rules within the `firewall` namespace.

### Topology

![Final Network Topology](topology.png)

The network topology consists of separate subnetworks for `client1`, `client2`, and `server` namespaces, as well as a `host-to-firewall` connection. These are orchestrated to ensure that controlled communication is maintained through the `firewall`, which facilitates both internal namespace communication and external internet access.

### Detailed Firewall Rules

- **Client1** can ping to **Server**.
- **Client2** can access the **Server** for HTTP services.
- **Client2** can ping to **Firewall**.
- **Client1** does not have ping permission to the **Firewall**.
- Both **Client** and **Server** networks can access the internet from the **Firewall** namespace via your host machine.


## Scripts

- `setup.sh`: Script for initializing namespaces, veth pairs, IP configurations, and gateways.
- `firewall_config.sh`: Script to clear existing iptables rules, configure NAT, and apply new firewall rules.
- `clear.sh`: Cleanup script to remove namespaces, veth pairs, and revert network configurations.
- `test_ping.sh`: Test script to test rules for pinging.
- `test_server.sh`: Test script to test server for HTML serving.
- `run_server.sh`: Script for opening HTML service in server.

### 1) setup.sh
Creating the namespaces

```bash
sudo ip netns add client1
sudo ip netns add client2
sudo ip netns add server
sudo ip netns add firewall
```

Creating virtual ethernet pairs
```bash
sudo ip link add veth_cl1_fw type veth peer name veth_fw_cl1
sudo ip link add veth_cl2_fw type veth peer name veth_fw_cl2
sudo ip link add veth_sv_fw type veth peer name veth_fw_sv
sudo ip link add veth_fw_host type veth peer name veth_host_fw
```

Linking virtual ethernet pairs to namespaces
```bash
sudo ip link set veth_cl1_fw netns client1
sudo ip netns exec client1 ip link set dev veth_cl1_fw up

sudo ip link set veth_cl2_fw netns client2
sudo ip netns exec client2 ip link set dev veth_cl2_fw up

sudo ip link set veth_sv_fw netns server
sudo ip netns exec server ip link set dev veth_sv_fw up

sudo ip link set veth_fw_cl1 netns firewall
sudo ip netns exec firewall ip link set dev veth_fw_cl1 up

sudo ip link set veth_fw_cl2 netns firewall
sudo ip netns exec firewall ip link set dev veth_fw_cl2 up

sudo ip link set veth_fw_sv netns firewall
sudo ip netns exec firewall ip link set dev veth_fw_sv up

sudo ip link set veth_fw_host netns firewall
sudo ip netns exec firewall ip link set dev veth_fw_host up
```

Assigning ip addresses to virtual ethernet pairs and getting them up
```bash
sudo ip netns exec client1 ip addr add 192.0.2.2/26 dev veth_cl1_fw && sudo ip netns exec client1 ip link set dev veth_cl1_fw up
sudo ip netns exec firewall ip addr add 192.0.2.1/26 dev veth_fw_cl1 && sudo ip netns exec firewall ip link set dev veth_fw_cl1 up

sudo ip netns exec client2 ip addr add 192.0.2.66/26 dev veth_cl2_fw && sudo ip netns exec client2 ip link set dev veth_cl2_fw up
sudo ip netns exec firewall ip addr add 192.0.2.65/26 dev veth_fw_cl2 && sudo ip netns exec firewall ip link set dev veth_fw_cl2 up

sudo ip netns exec server ip addr add 192.0.2.130/26 dev veth_sv_fw && sudo ip netns exec server ip link set dev veth_sv_fw up
sudo ip netns exec firewall ip addr add 192.0.2.129/26 dev veth_fw_sv && sudo ip netns exec firewall ip link set dev veth_fw_sv up

sudo ip netns exec firewall ip addr add 192.0.2.194/26 dev veth_fw_host && sudo ip netns exec firewall ip link set dev veth_fw_host up
```

Linking the virtual ethernet which is going host to firewall _(veth_host_fw)_ to host
```bash
#The veth_host_fw is distinct from other virtual Ethernet devices as it is the only one linked directly to the host.
sudo ip link set veth_host_fw up
sudo ip addr add 192.0.2.193/26 dev veth_host_fw
```

Assigning default gateways to namespaces
```bash
sudo ip netns exec client1 ip route add default via 192.0.2.1
sudo ip netns exec client2 ip route add default via 192.0.2.65
sudo ip netns exec server ip route add default via 192.0.2.129
sudo ip netns exec firewall ip route add default via 192.0.2.193
```

Adding routing rules to host. This is similar to giving host to a default gateway in order to allow the traffic form host to LAN
```bash
sudo route add -net 192.0.2.0 netmask 255.255.255.192 gw 192.0.2.194 dev veth_host_fw
sudo route add -net 192.0.2.64 netmask 255.255.255.192 gw 192.0.2.194 dev veth_host_fw
sudo route add -net 192.0.2.128 netmask 255.255.255.192 gw 192.0.2.194 dev veth_host_fw
```
### 2) firewall_config.sh
Deleting existing firewall rules
```bash
sudo ip netns exec firewall iptables -F INPUT
sudo ip netns exec firewall iptables -F FORWARD
```
Allow forwarding on the host machine
```bash
sudo sysctl net.ipv4.ip_forward=1
```
Allow forwarding on the firewall
```bash
sudo ip netns exec firewall sysctl net.ipv4.ip_forward=1
```
Configuring Network Adress Translation
```bash
sudo iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE
```
Firewall **INPUT** rules
```bash
#accept packets if state is established before
sudo ip netns exec firewall iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
#drop incoming packets from client1
sudo ip netns exec firewall iptables -A INPUT -s 192.0.2.0/26 -j DROP
#accept incoming packets from client2
sudo ip netns exec firewall iptables -A INPUT -s 192.0.2.64/26 -j ACCEPT
```
Firewall **FORWARD** rules
```bash
#forward packets if state is established before
sudo ip netns exec firewall iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
#drop packets coming from client1 going to server port80 (client1 cant access to server for http)
sudo ip netns exec firewall iptables -A FORWARD -s 192.0.2.0/26 -d 192.0.2.128/26 -p tcp --dport 80 -j DROP
#forward packets coming from client2 going to servers port80
sudo ip netns exec firewall iptables -A FORWARD -s 192.0.2.64/26 -d 192.0.2.128/26 -p tcp --dport 80 -j ACCEPT
```
## Conclusion

The iptables firewall project successfully illustrates the use of iptables as a stateful firewall in a network with multiple subnets. The firewall controls traffic between clients and a server, and manages internet access, aligning with the defined security policies.

## Appendix

- **Subnetworks**:
  - `Client1`: 192.0.2.0/26
  - `Client2`: 192.0.2.64/26
  - `Server`: 192.0.2.128/26
  - `Host-To-Firewall`: 192.0.2.192/26
