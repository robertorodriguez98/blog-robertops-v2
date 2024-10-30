---
title: Instalación de k3s utilizando Ansible
published: 2024-10-24
description: ''
image: ''
tags: []
category: ''
draft: true 
lang: ''
---
## Preparación del escenario

Para crear el escenario se va a usar **Vagrant**, utilizando el siguiente `Vagrantfile`:
```ruby
Vagrant.configure("2") do |config|
    config.vm.box = "debian/bookworm64"
    config.vm.box_check_update = false
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.provider "libvirt" do |v|
      v.memory = 2048
      v.cpus = 3
      v.driver = "qemu"
    end
    config.vm.define "master" do |master|
      master.vm.hostname = "master"
      master.vm.network "private_network",
        :libvirt__network_name => "k3s-vagrant",
        :ip => "10.10.10.10",
        :libvirt__dhcp_enabled => false,
        :libvirt__forward_mode => "veryisolated"
    end
    config.vm.define "nodo1" do |nodo1|
      nodo1.vm.hostname = "nodo1"
      nodo1.vm.network "private_network",
        :libvirt__network_name => "k3s-vagrant",
        :ip => "10.10.10.20",
        :libvirt__dhcp_enabled => false,
        :libvirt__forward_mode => "veryisolated"
    end
    config.vm.define "nodo2" do |nodo2|
      nodo2.vm.hostname = "nodo2"
      nodo2.vm.network "private_network",
        :libvirt__network_name => "k3s-vagrant",
        :ip => "10.10.10.30",
        :libvirt__dhcp_enabled => false,
        :libvirt__forward_mode => "veryisolated"
    end
  end
```


master
```shell
export KUBECONFIG=~/.kube/config
mkdir ~/.kube 2> /dev/null
chmod 600 "$KUBECONFIG"
sudo k3s kubectl config view --raw > "$KUBECONFIG"
```

una vez instalado kubernetes, copiamos la configuración de kubernetes del plano de control a nuestro kubeconfig :

```shell
export KUBECONFIG=~/.kube/config
mkdir ~/.kube 2> /dev/null
chmod 600 "$KUBECONFIG"
ssh -i .vagrant/machines/plano-control/virtualbox/private_key vagrant@192.168.56.10 'sudo k3s kubectl config view --raw' > ~/.kube/config
```

y en el fichero modificamos la ip de localhost por la de la máquina:
```shell
sed -i 's/127\.0\.0\.1/192\.168\.56\.10/g' $KUBECONFIG
```

Finalmente podemos usar kubectl.

```shell
❯ kubectl get nodes
NAME            STATUS   ROLES                  AGE   VERSION
nodo1           Ready    <none>                 15m   v1.30.5+k3s1
nodo2           Ready    <none>                 14m   v1.30.5+k3s1
plano-control   Ready    control-plane,master   15m   v1.30.5+k3s1
```