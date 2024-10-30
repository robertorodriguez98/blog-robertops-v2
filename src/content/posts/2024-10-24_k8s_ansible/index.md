---
title: Instalación de kubernetes utilizando Ansible
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

## Instalación k8s

Para instalar kubernetes se va a utilizar [k3s](https://k3s.io/), que se instala siguiendo estos pasos:

* en el **plano de control**:
  ```shell
  curl -sfL https://get.k3s.io | sh -
  ```
  después se obtiene el token en `/var/lib/rancher/k3s/server/node-token`
* en los nodos:
  ```shell
  curl -sfL https://get.k3s.io | K3S_URL=https://[ip plano control]:6443 K3S_TOKEN=[token] sh -
  ```

### Ansible

sin embargo, nos interesa automatizar dicho proceso ya que haciendo esto permite escalar el número de nodos fácilmente. para ello, se va a usar [ansible](https://www.ansible.com/). Se han configurado los siguientes ficheros.

### Inventario

```yaml
all:
  children:
    planos_control:
      hosts:
        p_nodo: 
          ansible_ssh_host: 192.168.56.10
          ansible_ssh_user: vagrant
          ansible_ssh_private_key_file: ../.vagrant/machines/plano-control/virtualbox/private_key
    trabajadores:
      hosts:
        nodo1: 
          ansible_ssh_host: 192.168.56.20
          ansible_ssh_user: vagrant
          ansible_ssh_private_key_file: ../.vagrant/machines/nodo1/virtualbox/private_key
        nodo2: 
          ansible_ssh_host: 192.168.56.30
          ansible_ssh_user: vagrant
          ansible_ssh_private_key_file: ../.vagrant/machines/nodo2/virtualbox/private_key

  vars:
    token_k3s: ""
    token_k3s_base64: ""
    ip_pcontrol: "192.168.56.10"
```

### Playbook

```yaml
- hosts: all
  become: true
  tasks:
    - name: Actualizamos el sistema
      apt: update_cache=yes upgrade=yes
    - name: nos aseguramos de que curl esté instalado
      apt:
        pkg: 
          - curl

- hosts: planos_control
  become: true
  tasks:
    # Para que no haya problemas de certificados al usar kubectl, añadimos la IP del plano de control durante la instalación de k3s.
    - name: instalamos k3s
      shell: "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--tls-san {{ ip_pcontrol }}' sh -"
    - name: sacar token
      ansible.builtin.slurp:
        src: "/var/lib/rancher/k3s/server/node-token"
      register: token_k3s_base64
    - name: descodificar token
      ansible.builtin.set_fact:
        token_k3s: "{{ token_k3s_base64.content | ansible.builtin.b64decode | replace('\n', '' ) }}"
    - debug: msg="el token es {{token_k3s}}"

- hosts: trabajadores
  become: true
  tasks:
    - name: instalamos k3s con el token
      shell: "curl -sfL https://get.k3s.io | K3S_URL=https://{{ ip_pcontrol }}:6443 K3S_TOKEN={{ hostvars['p_nodo'].token_k3s }} sh -"
```
