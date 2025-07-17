#!/bin/bash

# Worker node setup script
# This script contains step 12 from the README.md

set -e

MASTER_IP=$1

echo "=========================================="
echo "Starting Kubernetes worker node setup..."
echo "Master IP: $MASTER_IP"
echo "=========================================="

# Step 12: Join the cluster
echo "Step 12: Joining the Kubernetes cluster..."

# Wait for the join command to be available
while [ ! -f /vagrant/join-command.sh ]; do
  echo "Waiting for join command from master node..."
  sleep 10
done

# Wait a bit more to ensure master is fully ready
sleep 30

# Execute the join command
echo "Executing join command..."
sudo bash /vagrant/join-command.sh

# Verify the join was successful
echo "Waiting for node to be ready..."
sleep 30

echo "=========================================="
echo "Kubernetes worker node setup completed!"
echo "=========================================="
echo "Node should now be part of the cluster."
echo "You can check the status from the master node using:"
echo "  vagrant ssh k8s-master"
echo "  kubectl get nodes"
echo "=========================================="