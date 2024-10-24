---
title: Recolección centralizada de logs de sistema, mediante Journald
published: 2023-01-15
image: "./featured.png"
tags: ["journald", "logs","OpenStack"]
category: Documentación
draft: false
---

El escenario de OpenStack es el siguiente:

![escenario](https://i.imgur.com/I7aSQqg.png)

## Enunciado

Implementa en tu escenario de trabajo de Openstack, un sistema de recolección de log mediante journald. Para ello debes, implementar un sistema de recolección de log mediante el paquete systemd-journal-remote, o similares.

## Preparación

En cada instancia, voy a instalar el paquete `systemd-journal-remote`; en alfa, charlie y delta ejecuto el siguiente comando:

```bash
apt install systemd-journal-remote
```

en bravo, ejecuto el siguiente comando:

```bash
sudo dnf install systemd-journal-remote
```

## Configuración

He elegido el servidor alfa como servidor de logs, por lo que en él, voy a configurar el servicio. No voy a usar https ni autenticación, por lo que en el fichero `/lib/systemd/system/systemd-journal-remote.service` voy a modificar la siguientes línea:

```bash
ExecStart=/lib/systemd/systemd-journal-remote --listen-http=-3 --output=/var/log/journal/remote/
```

Ahora inicio el servicio y lo habilito para que se inicie en el arranque:

```bash
sudo systemctl enable --now systemd-journal-remote.socket
sudo systemctl enable --now systemd-journal-remote.service

sudo systemctl status systemd-journal-remote.socket
sudo systemctl status systemd-journal-remote.service
```

![status](https://i.imgur.com/nKnk0fe.png)

## Configuración de los clientes

Para ello, en cada uno crearé un usuario llamado `systemd-journal-upload` configurado de la siguiente manera:

**en charlie y delta**

```bash
sudo adduser --system --home /run/systemd --no-create-home --disabled-login --group systemd-journal-upload
```

**en bravo**

```bash
sudo adduser --system --home-dir /run/systemd --no-create-home --user-group systemd-journal-upload
```

Ahora modifico en el fichero `/etc/systemd/journal-upload.conf` la siguiente línea:

```bash
URL=http://alfa.roberto.gonzalonazareno.org:19532
```

Ahora reinicio el servicio en todas las máquinas:

```bash
sudo systemctl restart systemd-journal-upload.service
```

## Comprobación

En el servidor alfa, voy a comprobar que se están recibiendo los logs de los clientes

![logs](https://i.imgur.com/4HNPxgv.png)

Para ver los logs de los clientes, en el servidor alfa, ejecuto el siguiente comando (en este caso, el de delta):

```bash
sudo journalctl --file /var/log/journal/remote/remote-192.168.0.3.journal
```

![logs](https://i.imgur.com/qnJuI9g.png)

En un ejemplo anterior: [Ejemplo completo: Desplegando y accediendo a la aplicación Temperaturas](https://github.com/josedom24/curso_kubernetes_ies/blob/main/modulo6/temperaturas.md) habíamos desplegado una aplicación formada por dos microservicios que nos permitía visualizar las temperaturas de municipios.
