#start
sudo ip netns add client1
sudo ip netns add client2
sudo ip netns add server
sudo ip netns add firewall

echo "Created Namespaces: "

sudo ip netns list

#Creating virtual ethernet connections
sudo ip link add veth_cl1_fw type veth peer name veth_fw_cl1
sudo ip link add veth_cl2_fw type veth peer name veth_fw_cl2
sudo ip link add veth_sv_fw type veth peer name veth_fw_sv
sudo ip link add veth_fw_host type veth peer name veth_host_fw


#linking neamesapces and veths
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



#Assigning IP addresses
sudo ip netns exec client1 ip addr add 192.0.2.2/26 dev veth_cl1_fw && sudo ip netns exec client1 ip link set dev veth_cl1_fw up
sudo ip netns exec firewall ip addr add 192.0.2.1/26 dev veth_fw_cl1 && sudo ip netns exec firewall ip link set dev veth_fw_cl1 up

sudo ip netns exec client2 ip addr add 192.0.2.66/26 dev veth_cl2_fw && sudo ip netns exec client2 ip link set dev veth_cl2_fw up
sudo ip netns exec firewall ip addr add 192.0.2.65/26 dev veth_fw_cl2 && sudo ip netns exec firewall ip link set dev veth_fw_cl2 up

sudo ip netns exec server ip addr add 192.0.2.130/26 dev veth_sv_fw && sudo ip netns exec server ip link set dev veth_sv_fw up
sudo ip netns exec firewall ip addr add 192.0.2.129/26 dev veth_fw_sv && sudo ip netns exec firewall ip link set dev veth_fw_sv up

sudo ip netns exec firewall ip addr add 192.0.2.194/26 dev veth_fw_host && sudo ip netns exec firewall ip link set dev veth_fw_host up


#link virtual eth host_to_firewall to host
sudo ip link set veth_host_fw up
sudo ip addr add 192.0.2.193/26 dev veth_host_fw


#Assigning gateways
sudo ip netns exec client1 ip route add default via 192.0.2.1
sudo ip netns exec client2 ip route add default via 192.0.2.65
sudo ip netns exec server ip route add default via 192.0.2.129
sudo ip netns exec firewall ip route add default via 192.0.2.193

#routing from host to firewall
sudo route add -net 192.0.2.0 netmask 255.255.255.192 gw 192.0.2.194 dev veth_host_fw
sudo route add -net 192.0.2.64 netmask 255.255.255.192 gw 192.0.2.194 dev veth_host_fw
sudo route add -net 192.0.2.128 netmask 255.255.255.192 gw 192.0.2.194 dev veth_host_fw
