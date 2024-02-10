for i in {3..1}
do
  echo "[+] Test script is starting in *$i*"
  sleep 1
done


printf "Rule 1) Client1 should ping the server\n"
sleep 3
echo "----------------------------------------------------------------------"
sudo ip netns exec client1 ping -c 3 192.0.2.130
printf "\n[+] Pings sent successfully!\n\n"
echo "----------------------------------------------------------------------"
sleep 3


printf "Rule 2) Client2 should ping the Firewall\n"
sleep 3
echo "----------------------------------------------------------------------"
sudo ip netns exec client2 ping -c 3 192.0.2.65
printf "\n[+] Pings sent successfully!\n\n"
echo "----------------------------------------------------------------------"
sleep 3

printf "Rule 3) Client1 should NOT ping the Firewall\n\n"
sleep 3
echo "----------------------------------------------------------------------"
sudo ip netns exec client1 ping -c 1 192.0.2.1
printf "[+] Cant sent!\n\n"
echo "----------------------------------------------------------------------"
sleep 3

printf "Rule 4) Both Client and Server networks can be access to the internet\n\n"
sleep 3
printf "\n[+] Pinging google.com from Client1\n"
sleep 3
echo "----------------------------------------------------------------------"
sudo ip netns exec client1 ping -c 3 google.com
printf "\n[+] Pings sent successfully!\n"
echo "----------------------------------------------------------------------"
sleep 3

printf "\n[+] Pinging google.com from Client2\n"
sleep 3
echo "----------------------------------------------------------------------"
sudo ip netns exec client2 ping -c 3 google.com
echo "----------------------------------------------------------------------"
printf "\n[+] Pings sent successfully!\n"
sleep 3

printf "\n[+] Pinging google.com from Server\n"
sleep 3
echo "----------------------------------------------------------------------"
sudo ip netns exec server ping -c 3 google.com
printf "\n[+] Pings sent successfully!\n"
echo "----------------------------------------------------------------------"
sleep 3