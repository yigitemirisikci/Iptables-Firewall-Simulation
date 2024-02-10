# Function to delete a network namespace if it exists
delete_netns() {
    if sudo ip netns list | grep -q $1; then
        sudo ip netns delete $1
        echo "Deleted namespace: $1"
    else
        echo "Namespace $1 does not exist, skipping."
    fi
}

# Function to delete a veth pair if it exists
delete_veth() {
    if ip link show | grep -q $1; then
        sudo ip link delete $1
        echo "Deleted veth pair: $1"
    else
        echo "Veth pair $1 does not exist, skipping."
    fi
}

# Function to delete a bridge if it exists
delete_bridge() {
    if brctl show | grep -q $1; then
        sudo ip link set $1 down
        sudo brctl delbr $1
        echo "Deleted bridge: $1"
    else
        echo "Bridge $1 does not exist, skipping."
    fi
}

# Delete network namespaces
delete_netns client1
delete_netns client2
delete_netns server
delete_netns firewall

# Delete veth pairs
delete_veth veth_cl1_fw
delete_veth veth_cl2_fw
delete_veth veth_sv_fw
delete_veth veth_fw_host

# Delete the bridge
delete_bridge bridge000

echo "Cleanup complete."
