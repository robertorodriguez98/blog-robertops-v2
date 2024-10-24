---
title: "Snort: Instalación y primeros pasos"
published: 2022-10-10
image: "./featured.jpg"
tags: ["debian","snort"]
category: Documentación
draft: false
---

**Enunciado:**

1. Instalación
2. Configuración Red
3. Reglas def
4. Reglas propias
5. Opciones reglas
6. Demo uso
7. Alertas
8. Acciones


## Instalación

El paquete de **Snort** se encuentra en los repositorios de debian, por lo que podemos instalarlo directamente con apt:

```bash
sudo apt update
sudo apt install snort
```

con `snort -V` podemos comprobar que se ha instalado correctamente:
![pruebainstalacion](pruebainstalacion.png)

### Configuración de la red

Tras instalarlo, iniciará la configuración de la red. En la configuración que se abre, podemos seleccionar la ip/rango de ips de la máquina, aunque más adelante modificando el fichero de configuración, podemos elegir que utilice solo una interfaz de red o todas (la opción por defecto).
![instalacion](instalacion.png)
Para modificar las opciones tras la instalación tenemos que modificar el fichero `/etc/snort/snort.debian.conf` (al tratarse de una instalación en debian, se carga el contenido de este fichero antes que la propia configuración de snort). Concretamente nos interesan las siguientes líneas:


 DEBIAN_SNORT_STARTUP="boot"
 DEBIAN_SNORT_HOME_NET="10.0.0.0/8"
 DEBIAN_SNORT_OPTIONS=""
 DEBIAN_SNORT_INTERFACE="enp7s0"
 DEBIAN_SNORT_SEND_STATS="false"
 DEBIAN_SNORT_STATS_RCPT="root"
 DEBIAN_SNORT_STATS_THRESHOLD="1"


Como el propio fichero indica, después de modificarlo tenemos que ejecutar el siguiente comando para que la configuración se actualice:

```bash
sudo dpkg-reconfigure snort
```

Tras la ejecución del comando, reconfiguramos Snort, decidiendo cuando se ejecuta, las interfaces e ips, si activamos el modo promiscuo, y por último si queremos que se cree una tarea de cron para mandar correos diariamente con el resultado del log. 

## Reglas

Para configurar los grupos de reglas que queremos activar, tenemos que editar el fichero de configuración `/etc/snort/snort.conf`:
![rutasreglas](rutasreglas.png)
En la instalación que se realiza de los repositorios de debian, están incluidas las reglas de la comunidad. En el caso de que queramos utilizar una set de reglas concreta, habría que descomentar el set específico. También se puede observar en la imagen como el fichero de reglas personalizadas está activo (`local.rules`).

### Reglas propias

De momento el fichero de reglas propias está vacío. Las reglas se construyen de la siguiente manera:
![estructura](estructuraregla.png)
Como podemos ver, La regla consta de dos partes principales, la **cabecera**, que contiene información relacionada con la red, y las **opciones**, que contienen detalles de invenstigación de paquetes. La regla que se muestra a continuación, sirve para detectar que se está realizando un ping a la máquina:

alert icmp any any -> $HOME_NET any (msg:"Ping detectado";sid:1000001;rev:1)


vamos a analizar la regla:
|Estructura|Valor|Descripción|
|---|---|---|
|Action|alert|le dice a snort que hacer cuando la regla salta|
|Protocol|icmp|Protocolo a ser analizado (TCP, UDP, ICMP, IP)|
|Source IP|any|Direcciones IP de origen|
|Source Port|any|Puertos de origen|
|Direction|->|Operador de dirección. Determina la dirección del tráfico|
|Destination IP|$HOME_NET|Direcciones IP de destino|
|Destination Port|any|Puertos de destino|
|Message|msg:"Ping detectado"|Mensaje a mostrar cuando aplique la regla|
|Rule ID|sid:1000001| ID único de la regla|
|Revision info|rev:1|Información de revisión|

### Demo de la regla

Una vez hemos añadido al regla al fichero de `local.rules`, ya podemos probar la regla. Vamos a ejecutar snort en modo consola para que muestre el resultado en pantalla (`-A console`):

```shell
sudo snort -A console -q -c /etc/snort/snort.conf -i enp1s0
```

![pruebaping](pruebaping.png)

MHicxeRVZ6cSE6usNUu2HNRbI