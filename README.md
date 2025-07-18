# k8s-demo

+ 系统环境: Debian 12
+ K8s版本：1.32.7
+ Calico版本：3.30.2

利用Vagrant+VirtualBox搭建的1主1从的k8s集群

# 使用

## 安装步骤

```bash
vagrant up k8s-master
vagrant up k8s-worker1
```

## 进入k8s-master
```bash
vagrant ssh k8s-master
```

在k8s-master中执行以下命令查看集群状态
```bash
kubectl get nodes -o wide
kubectl get po --all-namespaces
```

## Vagrantfile修改后重启虚拟机
```bash
vagrant reload k8s-master
vagrant reload k8s-worker1
```

## 在宿主机上使用k8s
```bash
curl -LO "https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 配置 kubeconfig
export KUBECONFIG=./kubeconfig/config

# 验证安装
kubectl version
kubectl get nodes -o wide
```

## 安装helm
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add harbor https://helm.goharbor.io
helm repo update
kubectl create namespace harbor
helm install harbor harbor/harbor --namespace harbor
```

## 安装kubepi
```bash
kubectl apply -f https://raw.githubusercontent.com/1Panel-dev/KubePi/master/docs/deploy/kubectl/kubepi.yaml # 无持久化
```

## 安装harbor
```bash
kubectl apply -f harbor/local-storage.yaml
kubectl apply -f harbor/harbor-pv-pvc.yaml
helm install harbor harbor/harbor -f harbor/values.yaml -n harbor

helm upgrade harbor harbor/harbor -f harbor/values.yaml -n harbor # 升级
```



