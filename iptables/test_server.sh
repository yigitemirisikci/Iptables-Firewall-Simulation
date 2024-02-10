sudo echo "[+] Test script is starting in *3*"
sleep 1
for i in {2..1}
do
  echo "[+] Test script is starting in *$i*"
  sleep 1
done


# Check if run_server.sh is running
if ! pgrep -f "run_server.sh" > /dev/null; then
  printf "[Warning!] Please start run_server.sh \n"
  exit 1
fi

printf "[+] Started...\n"
echo "----------------------------------------------------------------------"
printf "\nClient2 should access to the server for http\n"
echo "----------------------------------------------------------------------"
sleep 3

sudo ip netns exec client2 wget http://192.0.2.130/news.html


echo "----------------------------------------------------------------------"
printf "\n[+] HTML Downloaded Successfully\n"
sleep 3

printf "\nClient1 should NOT access to the server for http\n"
sleep 3
echo
echo "----------------------------------------------------------------------"



if ! sudo timeout 3 ip netns exec client1 wget -O - -o /dev/stderr -v http://192.0.2.130/news.html; then
  echo "----------------------------------------------------------------------"
  printf "\n[+] Can't connect to server\n" >&2
fi

