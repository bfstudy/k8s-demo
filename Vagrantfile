# -*- mode: ruby -*-
# vi: set ft=ruby :

# Kubernetes cluster configuration
MASTER_IP = "192.168.56.100"
WORKER_IP = "192.168.56.101"
POD_NETWORK_CIDR = "192.168.0.0/16"

Vagrant.configure("2") do |config|
  # Base box
  config.vm.box = "ubuntu/jammy64"
  
  # Common configuration
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
  end

  # Master node
  config.vm.define "k8s-master" do |master|
    master.vm.hostname = "k8s-master"
    
    # Private network for cluster communication
    master.vm.network "private_network", ip: MASTER_IP
    
    # Public network for external access (bridged mode)
    # master.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)"
    
    # Port forwarding for K8s API server (alternative to public network)
    master.vm.network "forwarded_port", guest: 6443, host: 6443, protocol: "tcp"
    # Port forwarding for NodePort services range
    # Add more NodePort mappings as needed (30000-32767 range)
    master.vm.network "forwarded_port", guest: 30080, host: 30080
    
    master.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-master"
      vb.memory = "4096"
      vb.cpus = 2
    end
    
    master.vm.provision "shell", path: "common.sh"
    master.vm.provision "shell", path: "master.sh", args: [MASTER_IP, POD_NETWORK_CIDR]
    
    # Copy kubeconfig to host for external access
    master.vm.provision "shell", inline: <<-SHELL
      # Wait for kubeconfig to be ready
      while [ ! -f /home/vagrant/.kube/config ]; do
        sleep 5
      done
      
      # Copy kubeconfig to shared folder
      mkdir -p /vagrant/kubeconfig
      cp /home/vagrant/.kube/config /vagrant/kubeconfig/config
      
      # Modify server address for external access
      sed -i 's|server: https://.*:6443|server: https://127.0.0.1:6443|' /vagrant/kubeconfig/config
      
      echo "Kubeconfig copied to ./kubeconfig/config"
      echo "To access cluster from host, run:"
      echo "export KUBECONFIG=./kubeconfig/config"
    SHELL
  end

  # Worker node
  config.vm.define "k8s-worker1" do |worker|
    worker.vm.hostname = "k8s-worker1"
    
    # Private network for cluster communication
    worker.vm.network "private_network", ip: WORKER_IP
    
    # Public network for external access (bridged mode)
    # worker.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)"
    
    # Port forwarding for NodePort services on worker
    worker.vm.network "forwarded_port", guest: 30000, host: 30010, protocol: "tcp"
    worker.vm.network "forwarded_port", guest: 30001, host: 30011, protocol: "tcp"
    worker.vm.network "forwarded_port", guest: 30002, host: 30012, protocol: "tcp"
    
    worker.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-worker1"
      vb.memory = "4096"
      vb.cpus = 2
    end
    
    worker.vm.provision "shell", path: "common.sh"
    worker.vm.provision "shell", path: "worker.sh", args: [MASTER_IP]
  end
end