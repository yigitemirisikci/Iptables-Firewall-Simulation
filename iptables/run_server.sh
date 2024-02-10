printf "[+] Server is starting...\n\n"
sudo ip netns exec server bash -c 'cd "/home/yigit/Downloads" && sudo python3 -m http.server 80'
