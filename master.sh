#!/bin/bash

MASTER_IP=$1
POD_NETWORK_CIDR=$2

# Function to wait for resource to be ready
wait_for_resource() {
    local resource=$1
    local timeout=${2:-300}
    local namespace=${3:-default}
    
    echo "Waiting for $resource in namespace $namespace..."
    if [ "$namespace" = "default" ]; then
        kubectl wait --for=condition=Ready $resource --timeout=${timeout}s
    else
        kubectl wait --for=condition=Ready $resource -n $namespace --timeout=${timeout}s
    fi
}

# Function to wait for CRD to be established
wait_for_crd() {
    local crd=$1
    local timeout=${2:-300}
    
    echo "Waiting for CRD $crd to be established..."
    kubectl wait --for condition=established crd/$crd --timeout=${timeout}s
}

# Function to retry command
retry_command() {
    local command="$1"
    local max_attempts=${2:-3}
    local delay=${3:-10}
    
    for ((i=1; i<=max_attempts; i++)); do
        echo "Attempt $i/$max_attempts: $command"
        if eval "$command"; then
            echo "Command succeeded on attempt $i"
            return 0
        else
            echo "Command failed on attempt $i"
            if [ $i -lt $max_attempts ]; then
                echo "Retrying in $delay seconds..."
                sleep $delay
            fi
        fi
    done
    
    echo "Command failed after $max_attempts attempts"
    return 1
}

echo "Starting Kubernetes master setup..."

# Initialize Kubernetes cluster
echo "Initializing Kubernetes cluster..."
kubeadm init --apiserver-advertise-address=$MASTER_IP --pod-network-cidr=$POD_NETWORK_CIDR --kubernetes-version=1.32.0

# Configure kubectl for vagrant user
echo "Configuring kubectl for vagrant user..."
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# Configure kubectl for root user
echo "Configuring kubectl for root user..."
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config

# Wait for API server to be ready
echo "Waiting for API server to be ready..."
wait_for_resource "node/k8s-master" 300

# Install Calico network plugin
echo "Installing Calico network plugin..."

# Download manifests
echo "Downloading Calico manifests..."
retry_command "curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml" 3 5
retry_command "curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/custom-resources.yaml" 3 5

# Apply Tigera operator
echo "Installing Tigera operator..."
retry_command "kubectl apply -f tigera-operator.yaml" 3 10

# Wait for Tigera operator deployment
echo "Waiting for Tigera operator deployment..."
kubectl wait --for=condition=Available deployment/tigera-operator -n tigera-operator --timeout=300s

# Wait for all required CRDs
echo "Waiting for required CRDs..."
wait_for_crd "installations.operator.tigera.io" 300
wait_for_crd "apiservers.operator.tigera.io" 300

# Additional CRDs that might be needed
kubectl get crd | grep tigera || true

# Modify custom-resources.yaml
echo "Configuring custom resources..."
sed -i "s|192.168.0.0/16|$POD_NETWORK_CIDR|g" custom-resources.yaml

# Apply custom resources with retry
echo "Applying custom resources..."
retry_command "kubectl apply -f custom-resources.yaml" 5 15

# Wait for Calico installation to complete
echo "Waiting for Calico installation to complete..."
kubectl wait --for=condition=Ready installation/default --timeout=600s

# Wait for Calico pods to be ready
echo "Waiting for Calico pods to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=calico-node -n calico-system --timeout=300s

# Verify Calico installation
echo "Verifying Calico installation..."
kubectl get pods -n calico-system
kubectl get installation default -o yaml

# Generate join command for worker nodes
echo "Generating join command for worker nodes..."
kubeadm token create --print-join-command > /vagrant/join-command.sh
chmod +x /vagrant/join-command.sh

# Show final cluster status
echo "Final cluster status:"
kubectl get nodes -o wide
kubectl get pods --all-namespaces

echo "Master node setup completed successfully!"
echo "Join command saved to /vagrant/join-command.sh"