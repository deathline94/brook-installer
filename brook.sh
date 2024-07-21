#!/bin/bash

# Function to print characters with delay
print_with_delay() {
    text="$1"
    delay="$2"
    for ((i = 0; i < ${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo
}

# Introduction animation
echo ""
echo ""
print_with_delay "brook-installer by DEATHLINE | @NamelesGhoul" 0.1
echo ""
echo ""

# Check for and install required packages
install_required_packages() {
    REQUIRED_PACKAGES=("curl" "openssl")
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! command -v $pkg &> /dev/null; then
            apt-get update > /dev/null 2>&1
            apt-get install -y $pkg > /dev/null 2>&1
        fi
    done
}

# Check if the directory /root/brook already exists
if [ -d "/root/brook" ]; then
    echo "Brook seems to be already installed."
    echo ""
    echo "Choose an option:"
    echo ""
    echo "1) Reinstall"
    echo ""
    echo "2) Modify"
    echo ""
    echo "3) Uninstall"
    echo ""
    read -p "Enter your choice: " choice
    case $choice in
        1)
            # Reinstall
            rm -rf /root/brook
            systemctl stop brook
            pkill -f 'brook*'
            systemctl disable brook > /dev/null 2>&1
            rm /etc/systemd/system/brook.service
            ;;
        2)
            # Modify
            cd /root/brook
        
            # Get the current port and password from command line options
            current_port=$(ps aux | grep 'brook' | grep 'server' | awk '{for(i=1;i<=NF;i++){if($i=="-l"){print $(i+1);break}}}' | cut -d ':' -f 2)
            current_password=$(ps aux | grep 'brook' | grep 'server' | awk '{for(i=1;i<=NF;i++){if($i=="-p"){print $(i+1);break}}}')

            # Prompt the user for a new port and password
            echo ""
            read -p "Enter a new port (or press enter to keep the current one [$current_port]): " new_port
            [ -z "$new_port" ] && new_port=$current_port
            echo ""
            read -p "Enter a new password (or press enter to keep the current one [$current_password]): " new_password
            [ -z "$new_password" ] && new_password=$current_password
            echo ""

            # Kill the existing brook process, reload systemd and restart the brook service
            pkill -f 'brook*'
            sed -i "s/-l :$current_port/-l :$new_port/" /etc/systemd/system/brook.service
            sed -i "s/-p $current_password/-p $new_password/" /etc/systemd/system/brook.service
            systemctl daemon-reload
            systemctl start brook

            # Print client configs
            PUBLIC_IP=$(curl -s https://api.ipify.org)

            echo "Brook client config:"
            brook_config="brook client -l :1080 -i 127.0.0.1:$new_port -s $PUBLIC_IP:$new_port -p $new_password"
            echo "$brook_config"
            echo ""

            echo "Brook client URL:"
            brook_url="brook://$new_password@$PUBLIC_IP:$new_port"
            echo "$brook_url"
            echo ""
            exit 0
            ;;
        3)
            # Uninstall
            rm -rf /root/brook
            systemctl stop brook
            pkill -f 'brook'
            systemctl disable brook > /dev/null 2>&1
            rm /etc/systemd/system/brook.service
            echo "Brook uninstalled successfully!"
            echo ""
            exit 0
            ;;
        *)
            echo "Invalid choice."
            exit 1
            ;;
    esac
fi

# Install required packages if not already installed
install_required_packages

# Step 1: Check OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

# Determine binary name
BINARY_NAME=""
case "$OS" in
  Linux)
    case "$ARCH" in
      x86_64) BINARY_NAME="brook_linux_amd64";;
      386) BINARY_NAME="brook_linux_386";;
      arm64) BINARY_NAME="brook_linux_arm64";;
      arm) BINARY_NAME="brook_linux_arm";;
      *) echo "Unsupported architecture"; exit 1;;
    esac;;
  # Add more OS checks if needed
  *) echo "Unsupported OS"; exit 1;;
esac

# Step 2: Download the binary
mkdir -p /root/brook
cd /root/brook
wget -q "https://github.com/txthinking/brook/releases/latest/download/$BINARY_NAME"
chmod 755 "$BINARY_NAME"

# Step 3: Prompt user for input
echo ""
read -p "Enter a port (or press enter for a random port): " port
[ -z "$port" ] && port=$((RANDOM + 10000))

echo ""
read -p "Enter a password (or press enter for a random password): " password
[ -z "$password" ] && password=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1)

# Step 4: Run the binary and check the log
/root/brook/$BINARY_NAME server -l :$port -p $password > brook.log 2>&1 &

# Step 5: Create a system service
cat > /etc/systemd/system/brook.service <<EOL
[Unit]
Description=Brook VPN Service
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/root/brook
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/root/brook/$BINARY_NAME server -l :$port -p $password
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=5
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable brook > /dev/null 2>&1
systemctl start brook

# Step 6: Generate and print client config files
PUBLIC_IP=$(curl -s https://api.ipify.org)
echo ""
echo "Brook client config:"
echo ""
brook_config="brook client -l :1080 -i 127.0.0.1:$port -s $PUBLIC_IP:$port -p $password"
echo ""
echo "$brook_config"
echo ""
echo "Brook client URL:"
echo ""
brook_url="brook://$password@$PUBLIC_IP:$port"
echo ""
echo "$brook_url"
echo ""
