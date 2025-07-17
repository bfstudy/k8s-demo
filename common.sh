#!/bin/bash

# Common setup script for all Kubernetes nodes
# This script contains steps 1-7 from the README.md

set -e

echo "=========================================="
echo "Starting common Kubernetes node setup..."
echo "=========================================="

# Step 1: Update system
echo "Step 1: Updating system..."
sudo apt update && sudo apt upgrade -y

# Step 2: Disable Swap
echo "Step 2: Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Step 3: Configure hostname and hosts file
echo "Step 3: Configuring hosts file..."
cat <<EOF | sudo tee -a /etc/hosts
192.168.56.100 k8s-master
192.168.56.101 k8s-worker1
EOF

# Step 4: Install containerd
echo "Step 4: Installing containerd..."
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index and install containerd
sudo apt update
sudo apt install -y containerd.io

# Generate default configuration
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Modify configuration to enable systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart and enable containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Step 5: Configure kernel modules and system parameters
echo "Step 5: Configuring kernel modules and system parameters..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set system parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply system parameters
sudo sysctl --system

# Step 6: Add Kubernetes repository
echo "Step 6: Adding Kubernetes repository..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Step 7: Install kubelet, kubeadm and kubectl
echo "Step 7: Installing kubelet, kubeadm and kubectl..."
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Mark packages as hold to prevent automatic updates
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet
sudo systemctl enable kubelet

echo "=========================================="
echo "Common setup completed successfully!"
echo "=========================================="