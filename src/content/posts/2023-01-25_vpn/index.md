---
title: Redes Privadas Virtuales con OpenVPN
published: 2023-01-25
image: "./featured.png"
tags: ["VPN", "OpenVPN"]
category: Documentación
draft: false
---

## Caso A: VPN de acceso remoto con OpenVPN y certificados x509


* Uno de los dos equipos (el que actuará como servidor) estará conectado a dos redes
* Para la autenticación de los extremos se usarán obligatoriamente certificados digitales, que se generarán utilizando openssl y se almacenarán en el directorio `/etc/openvpn`, junto con  los parámetros Diffie-Helman y el certificado de la propia Autoridad de Certificación. * Se utilizarán direcciones de la red `10.99.99.0/24` para las direcciones virtuales de la VPN. La dirección `10.99.99.1` se asignará al servidor VPN. 
* Los ficheros de configuración del servidor y del cliente se crearán en el directorio /etc/openvpn de cada máquina, y se llamarán servidor.conf y cliente.conf respectivamente. 
* Tras el establecimiento de la VPN, la máquina cliente debe ser capaz de acceder a una máquina que esté en la otra red a la que está conectado el servidor. 
Documenta el proceso detalladamente.


El Escenario es el siguiente:

![escenario1](https://i.imgur.com/vob221j.png)

Vamos a generar dicho en Vagrant utilizando el siguiente Vagrantfile:

```ruby
Vagrant.configure("2") do |config|

config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.define :cliente do |cliente|
    cliente.vm.box = "debian/bullseye64"
    cliente.vm.hostname = "cliente"
    cliente.vm.network :private_network,
      :libvirt__network_name => "red-externa",
      :libvirt__dhcp_enabled => false,
      :ip => "192.168.0.20",
      :libvirt__netmask => '255.255.255.0',
      :libvirt__forward_mode => "veryisolated"
  end

  config.vm.define :servidor do |servidor|
    servidor.vm.box = "debian/bullseye64"
    servidor.vm.hostname = "servidor"
    servidor.vm.network :private_network,
      :libvirt__network_name => "red-externa",
      :libvirt__dhcp_enabled => false,
      :ip => "192.168.0.10",
      :libvirt__netmask => '255.255.255.0',
      :libvirt__forward_mode => "veryisolated"
    servidor.vm.network :private_network,
      :libvirt__network_name => "red-interna",
      :libvirt__dhcp_enabled => false,
      :ip => "192.168.1.10",
      :libvirt__netmask => '255.255.255.0',
      :libvirt__forward_mode => "veryisolated"
  end

  config.vm.define :maquina do |maquina|
    maquina.vm.box = "debian/bullseye64"
    maquina.vm.hostname = "maquina"
    maquina.vm.network :private_network,
      :libvirt__network_name => "red-interna",
      :libvirt__dhcp_enabled => false,
      :ip => "192.168.1.30",
      :libvirt__netmask => '255.255.255.0',
      :libvirt__forward_mode => "veryisolated"
  end
end
```

Ahora vamos a configurar las máquinas:

### Configuración de la máquina servidor

Vamos a instalar OpenVPN en la máquina servidor:

```bash
apt-get update
apt-get install openvpn
```

Activamos el bit de forwarding en el servidor editando el fichero `/etc/sysctl.conf` y descomentando la siguiente línea:

```bash
net.ipv4.ip_forward=1
```

y hacemos los cambios efectivos:

```bash
sudo sysctl -p
```

Como indica el enunciado, hay que copiar los ficheros del directorio `/usr/easy-rsa/` al directorio `/etc/openvpn/`:

```bash
cp -r /usr/share/easy-rsa /etc/openvpn
```

Ejecutamos el script de infraestructura de clave pública (PKI) para generar los certificados:

```bash
cd /etc/openvpn/easy-rsa
sudo ./easyrsa init-pki
```

Ahora podemos generar la clave privada:

```bash
sudo ./easyrsa build-ca
```

![builca](https://i.imgur.com/HnrLwoR.png)

Se guardarán en el directorio `/etc/openvpn/easy-rsa/pki/`.

Ahora generamos el certificado del servidor:

```bash
sudo ./easyrsa build-server-full server nopass
```

![buildserver](https://i.imgur.com/JWiael9.png)

Ahora vamos a generar los certificados diffie-helman (este proceso puede tardar varios minutos):

```bash
sudo ./easyrsa gen-dh
```

Por último, vamos a generar el certificado y la clave para la máquina cliente:

```bash
sudo ./easyrsa build-client-full cliente nopass
```

![buildclient](https://i.imgur.com/RRTumPA.png)

Como indica el comando, la clave se encuentra en `/etc/openvpn/easy-rsa/pki/private/cliente.key`y el certificado en `/etc/openvpn/easy-rsa/pki/issued/cliente.crt`.


Ahora copiamos los ficheros del cliente a la máquina cliente:

primero los movemos al directorio home:

```bash
sudo cp /etc/openvpn/easy-rsa/pki/ca.crt ~
sudo mv /etc/openvpn/easy-rsa/pki/issued/cliente.crt ~
sudo mv /etc/openvpn/easy-rsa/pki/private/cliente.key ~
```

Cambiamos el propietario de los ficheros (aprovechando que los tres ficheros empiezan por c*):

```bash
sudo chown vagrant: c*
```

Y ahora los copiamos a la máquina  (aprovechando también que los tres ficheros empiezan por c* para ahorrar código):

```bash
scp c* vagrant@cliente:/home/vagrant
```

![scp](https://i.imgur.com/04lHcb0.png)

utilizando como plantilla el fichero que se encuentra en `/usr/share/doc/openvpn/examples/sample-config-files/server.conf`, creamos el fichero de configuración del servidor en `/etc/openvpn/server/servidor.conf`:

```bash
port 1194
proto udp
dev tun

ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem

topology subnet

# DIRECCIONAMIENTO PARA EL TÚNEL
#
# El servidor será: 10.99.99.1

server 10.99.99.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt

push "route 192.168.1.0 255.255.255.0"

keepalive 10 120
cipher AES-256-CBC
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
verb 3
explicit-exit-notify 1
```

Ahora activamos el servicio de OpenVPN:

```bash
sudo systemctl enable --now openvpn-server@servidor
sudo systemctl status openvpn-server@servidor
```

![openvpnserver](https://i.imgur.com/S58gXhP.png)

### Configuración de la máquina cliente

Ahora vamos a configurar la máquina cliente. Primero instalamos OpenVPN:

```bash
sudo apt update
sudo apt install openvpn
```

Movemos los ficheros que hemos copiado de la máquina servidor a la máquina cliente a la ruta `/etc/openvpn/client/`:

```bash
sudo mv c* /etc/openvpn/client/
sudo chown root: /etc/openvpn/client/*
```

Al igual que con el servidor, tomando de ejemplo el fichero `/usr/share/doc/openvpn/examples/sample-config-files/client.conf`, creamos el fichero de configuración del cliente en `/etc/openvpn/client/cliente.conf`:

```bash
client
dev tun
proto udp
´
remote 192.168.0.10 1194
resolv-retry infinite
nobind

persist-key
persist-tun

ca /etc/openvpn/client/ca.crt
cert /etc/openvpn/client/cliente.crt
key /etc/openvpn/client/cliente.key

remote-cert-tls server
cipher AES-256-CBC
verb 3
```

Ahora activamos el servicio de OpenVPN:

```bash
sudo systemctl enable --now openvpn-client@cliente
sudo systemctl status openvpn-client@cliente
```

![openvpnclient](https://i.imgur.com/ErQ7bE9.png)

### Configuración de la máquina interna

Tenemos que cambiar la ruta por defecto también de la máquina interna para que sea a través del servidor:

```bash
sudo ip route del default
sudo ip route add default via 192.168.1.10
```

### Comprobación de funcionamiento

Ahora vamos a comprobar que funciona el túnel. En la máquina cliente, vamos a hacer un traceroute a la máquina de la red interna (de ip `192.168.1.30`):

```bash
traceroute 192.168.1.30
```

![traceroute1](https://i.imgur.com/mBLm0VW.png)

Como podemos ver, el primer salto es a la máquina servidor utilizando el túnel VPN del servidor, y el segundo salto es a la máquina de la red interna.

Podemos incluso, realizar una conexión SSH a la máquina de la red interna:

![ssh1](https://i.imgur.com/pnaKGtg.png)

---

## Caso B: VPN sitio a sitio con OpenVPN y certificados x509


* Cada equipo estará conectado a dos redes, una de ellas en común
  * Para la autenticación de los extremos se usarán obligatoriamente certificados digitales, que se generarán utilizando openssl y se almacenarán en el directorio /etc/openvpn, junto con con los parámetros Diffie-Helman y el certificado de la propia Autoridad de Certificación. 
  * Se utilizarán direcciones de la red 10.99.99.0/24 para las direcciones virtuales de la VPN. 
  * Tras el establecimiento de la VPN, una máquina de cada red detrás de cada servidor VPN debe ser capaz de acceder a una máquina del otro extremo.


El Escenario es el siguiente:

![escenario2](https://i.imgur.com/VGD6hgl.png)

Vamos a generar dicho en Vagrant utilizando el siguiente Vagrantfile:

```ruby
Vagrant.configure("2") do |config|

config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.define :maquina1 do |maquina1|
    maquina1.vm.box = "debian/bullseye64"
    maquina1.vm.hostname = "maquina1"
    maquina1.vm.network :private_network,
      :libvirt__network_name => "interna1",
      :libvirt__dhcp_enabled => false,
      :ip => "192.168.0.20",
      :libvirt__netmask => '255.255.255.0',
      :libvirt__forward_mode => "veryisolated"
  end

  config.vm.define :cliente do |cliente|
    cliente.vm.box = "debian/bullseye64"
    cliente.vm.hostname = "cliente"
    cliente.vm.network :private_network,
      :libvirt__network_name => "interna1",
      :libvirt__dhcp_enabled => false,
      :ip => "192.168.0.10",
      :libvirt__netmask => '255.255.255.0',
      :libvirt__forward_mode => "veryisolated"
    cliente.vm.network :private_network,
      :libvirt__network_name => "internet",
      :libvirt__dhcp_enabled => false,
      :ip => "10.20.30.1",
      :libvirt__netmask => '255.255.255.0',
      :libvirt__forward_mode => "veryisolated"
  end

  config.vm.define :servidor do |servidor|
    servidor.vm.box = "debian/bullseye64"
    servidor.vm.hostname = "servidor"
    servidor.vm.network :private_network,
      :libvirt__network_name => "internet",
      :libvirt__dhcp_enabled => false,
      :ip => "10.20.30.2",
      :libvirt__netmask => '255.255.255.0',
      :libvirt__forward_mode => "veryisolated"
    servidor.vm.network :private_network,
      :libvirt__network_name => "interna2",
      :libvirt__dhcp_enabled => false,
      :ip => "172.22.0.10",
      :libvirt__netmask => '255.255.0.0',
      :libvirt__forward_mode => "veryisolated"
  end

  config.vm.define :maquina2 do |maquina2|
    maquina2.vm.box = "debian/bullseye64"
    maquina2.vm.hostname = "maquina2"
    maquina2.vm.network :private_network,
      :libvirt__network_name => "interna2",
      :libvirt__dhcp_enabled => false,
      :ip => "172.22.0.20",
      :libvirt__netmask => '255.255.0.0',
      :libvirt__forward_mode => "veryisolated"
  end
end
```

Ahora configuraremos las máquinas;

### Configuración del servidor

La configuración es exactamente igual que en el caso anterior, por lo que tenemos que replicar la misma configuración (incluyendo copiar los ficheros al cliente) hasta el momento de editar el fichero `/etc/openvpn/server/servidor.conf`, donde empieza la configuración diferente.

Ahora creamos el fichero `/etc/openvpn/server/servidor.conf` con el siguiente contenido:

```bash
dev tun
ifconfig 10.99.99.1 10.99.99.2
route 192.168.0.0 255.255.255.0
tls-server

dh /etc/openvpn/easy-rsa/pki/dh.pem
ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key

comp-lzo
keepalive 10 60
log /var/log/openvpn/prueba.log

verb 3
```

```bash
sudo systemctl enable --now openvpn-server@servidor
sudo systemctl status openvpn-server@servidor
```

![servidor2](https://i.imgur.com/JFIpjzj.png)

### Configuración del cliente

Ahora vamos a configurar la máquina cliente. Primero instalamos OpenVPN:

```bash
sudo apt update
sudo apt install openvpn
```

Activamos el bit de forwarding en el servidor editando el fichero `/etc/sysctl.conf` y descomentando la siguiente línea:

```bash
net.ipv4.ip_forward=1
```

y hacemos los cambios efectivos:

```bash
sudo sysctl -p
```

Movemos los ficheros que hemos copiado de la máquina servidor a la máquina cliente a la ruta `/etc/openvpn/client/`:

```bash
sudo mv c* /etc/openvpn/client/
sudo chown root: /etc/openvpn/client/*
```

Al igual que con el servidor, tomando de ejemplo el fichero `/usr/share/doc/openvpn/examples/sample-config-files/client.conf`, creamos el fichero de configuración del cliente en `/etc/openvpn/client/cliente.conf`:

```bash
dev tun
remote 10.20.30.2
ifconfig 10.99.99.2 10.99.99.1
route 172.22.0.0 255.255.0.0
tls-client
ca /etc/openvpn/client/ca.crt
cert /etc/openvpn/client/cliente.crt
key /etc/openvpn/client/cliente.key
comp-lzo
keepalive 10 60
log /var/log/openvpn/cliente.log

verb 3
```

Ahora activamos el servicio de OpenVPN:

```bash
sudo systemctl enable --now openvpn-client@cliente
sudo systemctl status openvpn-client@cliente
```

![cliente2](https://i.imgur.com/DuigNzf.png)

### Configuramos las máquinas internas

Ahora vamos a configurar las rutas en las maquinas internas:

Máquina1:

```bash
sudo ip route del default
sudo ip route add default via 192.168.0.10
```

Máquina2:

```bash
sudo ip route del default
sudo ip route add default via 172.22.0.10
```

### Pruebas de funcionamiento

traceroute desde maquina1 a maquina2:

![traceroute2](https://i.imgur.com/xGemQ2V.png)

traceroute desde maquina2 a maquina1:

![traceroute3](https://i.imgur.com/g5BS0qP.png)