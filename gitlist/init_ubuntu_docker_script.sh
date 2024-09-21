
# ubuntu 24 lts 

#!/bin/bash

# This script installs Docker on Ubuntu, optimizes kernel parameters for Docker, and applies necessary settings.

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

echo "Updating system packages..."
apt-get update -y && apt-get upgrade -y

# Step 1: Install prerequisite packages
echo "Installing prerequisite packages..."
apt-get install apt-transport-https ca-certificates curl software-properties-common -y

# Step 2: Add Docker GPG key
echo "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Step 3: Add Docker APT repository
echo "Adding Docker APT repository..."
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Step 4: Install Docker
echo "Installing Docker..."
apt-get update -y
apt-get install docker-ce docker-ce-cli containerd.io -y

# Step 5: Start and enable Docker service
echo "Starting and enabling Docker service..."
systemctl start docker
systemctl enable docker

# Step 6: Add the current user to the Docker group (optional)
echo "Adding current user to the docker group..."
usermod -aG docker ${USER}

# Step 7: Optimize kernel parameters for Docker

# Set kernel parameters for Docker
echo "Optimizing kernel parameters for Docker..."

cat <<EOF >> /etc/sysctl.conf
# Docker sysctl settings
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
fs.may_detach_mounts=1
fs.file-max=1000000
vm.max_map_count=262144
EOF

# Apply sysctl changes
sysctl -p

# Step 8: Enable overlay and br_netfilter kernel modules
echo "Enabling overlay and br_netfilter modules..."
modprobe overlay
modprobe br_netfilter

# Ensure the modules load on boot
cat <<EOF > /etc/modules-load.d/docker.conf
overlay
br_netfilter
EOF

# Step 9: Configure Docker daemon with some basic performance improvements
echo "Configuring Docker daemon..."
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "max-concurrent-downloads": 10
}
EOF

# Step 10: Restart Docker to apply changes
echo "Restarting Docker to apply changes..."
systemctl restart docker

# Step 11: Check Docker status
echo "Docker installation and optimization completed!"
docker --version
systemctl status docker --no-pager

echo "You might need to log out and log back in to apply the Docker group changes."
