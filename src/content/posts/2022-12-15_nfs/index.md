---
title: Montaje NFS mediante systemd
published: 2022-12-15
image: "./featured.png"
tags: ["NFS", "OpenStack"]
category: Documentación
draft: false
---

En una instancia del cloud, basada en la distribución de tu elección, anexa un volumen de 2GB. En dicha instancia deberás configurar el servicio nfs de exportación y en el volumen un punto de montaje de la exportación mediante systemd.



### Escenario

El escenario se compone de dos máquinas, alfa, con debian 11 y que será el servidor nfs; y bravo, con rocky linux 8 y que será el cliente nfs. 

## Servidor NFS

Instalamos los paquetes necesarios para el servicio nfs:

```bash
apt install nfs-kernel-server nfs-common
```

Creamos el fichero  `/etc/systemd/system/mnt-carpeta.mount` con el siguiente contenido. El nombre del fichero, tiene que ser el mismo que el del punto de montaje en el que vamos a montar el dispositivo, además de sustituyendo las "/" por "-" (menos la primera):

```bash
[Unit]
Description=Montaje de disco para compartir

[Mount]
What= /dev/vdb
Where= /mnt/carpeta/
Type=ext4
Options=defaults

[Install]
WantedBy=multi-user.target
```

Activamos el servicio:

```bash
systemctl enable mnt-carpeta.mount
systemctl start mnt-carpeta.mount
```


Si no funciona el montaje de la unidad, podemos comprobar os errores con `journalctl -xe`

Tras el montaje podemos comprobar que el disco se ha montado correctamente:

![Montaje de disco](https://i.imgur.com/8cUkODO.png)

Finalmente, añadimos la siguiente línea al fichero `/etc/exports`:

```bash
/mnt/carpeta 172.16.0.0/16(rw,no_all_squash,no_subtree_check)
```

Y reiniciamos el servicio:

```bash
systemctl restart nfs-server
```


## Cliente NFS

Instalamos los paquetes necesarios para el servicio nfs:

```bash
dnf install nfs-utils
```

Podemos ver los dispositivos de bloques que se están compartiendo por nfs (la ip del servidor nfs es `172.16.0.1`):

```bash
showmount -e 172.16.0.1
```

![Dispositivos compartidos](https://i.imgur.com/oaYEhYA.png)

Creamos el fichero  `/etc/systemd/system/mnt-carpetaNFS.mount` con el siguiente contenido:

```bash
[Unit]
Description=Montaje del disco compartido por red usando NFS

[Mount]
What=172.16.0.1:/mnt/carpeta
Where=/mnt/carpetaNFS
Type=nfs
Options=defaults

[Install]
WantedBy=multi-user.target
```

Activamos el servicio:

```bash
systemctl enable mnt-carpetaNFS.mount
systemctl start mnt-carpetaNFS.mount
```

Podemos comprobar que el disco se ha montado correctamente:

![Montaje de disco 2](https://i.imgur.com/l4fEpSh.png)

## Comprobación

Comprobamos que el dispositivo de bloques se está compartiendo por nfs:

![Comprobación](https://i.imgur.com/16NCruU.png)

