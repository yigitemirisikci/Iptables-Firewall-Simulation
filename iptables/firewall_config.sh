#delete existing rules
sudo ip netns exec firewall iptables -F INPUT
sudo ip netns exec firewall iptables -F FORWARD

#forwarding in host
sudo sysctl net.ipv4.ip_forward=1
#forwarding in firewall
sudo ip netns exec firewall sysctl net.ipv4.ip_forward=1

#NAT
sudo iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE

#DNS configs
sudo ip netns exec client1 bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo ip netns exec client2 bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo ip netns exec server bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'


#configure firewall (iptables)

##INPUT RULES
#accept packets if state is established before
sudo ip netns exec firewall iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
#drop incoming packets from client1
sudo ip netns exec firewall iptables -A INPUT -s 192.0.2.0/26 -j DROP
#accept incoming packets from client2
sudo ip netns exec firewall iptables -A INPUT -s 192.0.2.64/26 -j ACCEPT


##FORWARD RULES
#forward packets if state is established before
sudo ip netns exec firewall iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
#drop packets coming from client1 going to server port80 (client1 cant access to server for http)
sudo ip netns exec firewall iptables -A FORWARD -s 192.0.2.0/26 -d 192.0.2.128/26 -p tcp --dport 80 -j DROP
#forward packets coming from client2 going to servers port80
sudo ip netns exec firewall iptables -A FORWARD -s 192.0.2.64/26 -d 192.0.2.128/26 -p tcp --dport 80 -j ACCEPT



echo "FIREWALL RULES:"
echo
sudo ip netns exec firewall iptables -L -v -n
