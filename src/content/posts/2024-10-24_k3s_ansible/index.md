---
title: Instalación de k3s utilizando Ansible
published: 2024-10-24
description: ''
image: ''
tags: []
category: ''
draft: false 
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

