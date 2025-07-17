# k8s-demo

系统环境: Debian 12
K8s版本：1.32
Calico版本：3.30.2

# 安装步骤

```bash
vagrant up k8s-master
vagrant up k8s-worker1
```

# 进入k8s-master
```bash
vagrant ssh k8s-master
```

```bash
kubectl get nodes -o wide
kubectl get po --all-namespaces
```

# Vagrantfile修改后重启虚拟机
```bash
vagrant reload k8s-master
```

