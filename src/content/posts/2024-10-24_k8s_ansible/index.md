---
title: Instalación de k8s utilizando Ansible
published: 2024-10-30
description: ''
image: ''
tags: []
category: ''
draft: true 
lang: ''
---
## Preparación del escenario

Se van a crear 3 máquinas virtuales, 1 actuará de plano de control, y las otras 2 serán nodos. Para crear el escenario se va a usar **Vagrant** con **virtualbox** como proveedor, utilizando el siguiente `Vagrantfile`:
```ruby
Vagrant.configure("2") do |config|
    config.vm.box = "debian/bookworm64"
    config.vm.box_check_update = false
    config.vm.synced_folder '.', '/vagrant', disabled: true
    config.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 2
    end
    config.vm.define "plano-control" do |pcontrol|
      pcontrol.vm.hostname = "plano-control"
      pcontrol.vm.network "private_network",
        ip: "192.168.56.10"
    end
    config.vm.define "nodo1" do |nodo1|
      nodo1.vm.hostname = "nodo1"
      nodo1.vm.network "private_network",
        ip: "192.168.56.20"
    end
    config.vm.define "nodo2" do |nodo2|
      nodo2.vm.hostname = "nodo2"
      nodo2.vm.network "private_network",
        ip: "192.168.56.30"
    end
  end
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

## Instalación k3s