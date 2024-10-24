---
title: Poblar un directorio LDAP desde un fichero CSV
published: 2023-02-22
image: "./featured.png"
tags: ["LDAP","OpenStack"]
category: Documentación
draft: false
---

En alfa creo el siguiente fichero CSV:

```csv
Belen,Nazareth,belennazareth@gmail.com,nazareth,ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC73j7AidXdLgiu5wJw7YgJuvOHyb6U8c04MuQyehYnMknMR8mTnWZr20npVHJ8VHYHDy8RlgbkMMBFgeVCgXJ+Im3A6Efp6HC4yj2SM+73hr1EKCLdRPzCzdtDSUtkqU9k+x2RdF3T6qD6H4Cg/nT8Sg3Qenqds4XORfDWOvntxFja2D0OhZv1MLPUD9pEj+a8D4erfiPx/gKW/Rtu89une+uiwVgK60B5CxnC8XXnXmPO3NhrgyQhVgzQZ658cUbLooxQURVlo1gnOmcqX5h+svUKN1SDbzTyy7HKSk7bbLHEhk7qDh7jSzcf80GLU0li8vXc2to8NpC00EOQ9POPivESz23gMNY8ooDtNU3Ll/xYvhtvXrJNTbuBiuVLzuopMvrQi6LVsQEWmPJzBiJ2qt8JW1KRLcnWRL4AezbxAPXuRYVnYBS3it6L0J4AZjZg63BkIIrfU7GYzrKb+z5mqUgDJhIZ4d5av+OAxPSSzNeVnyWEnWrI0k9kf9qmqhU= nazare@ThousandSunny 
Antonio,Marchan,antoniomarchan@gmail.com,anthony,ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9kx67eVF+Eh5epqZvQfjOLamYck9lVB9w1e/JO9Nzx7Utxm0ikD4ZCuhANc42RRkbH/2xICo138IpxJtfnbf4ObmaxVpo65lweLw5e8w132v6IXHkCAU5jTdyJS08Gi5I/nEqq/ywEMWJ939zEu0Dfdi/1IDlqBjGPpeomCJCDOkZWHfFyuiHrpgbWniwjRBcQiXjlp7w76/k0K+1Xw5JQz2F/YuTHzEGXqVo7x2T32IprzONXprVd9cn5qItFES5DMHOv62t++3zAOZbLNTs+cFuZmfTkT4YQUoHPkqXCzQmM6hnSAihOQjNKZWy+zSOiTkL22tdd9q4jhUZu4VutNeEFKt4VDlLH1uEV0FCJjb5Fw2gzb62D9sjdsjNa8EZD2IcrjKrIJv83Ca7AyeED5egoFSAMfW1iFIse8pG4olOOv4FyeWtSgjgv9A+URiwkRqFd371lw6Xj0gdEokqO9sBYlcy3gfwT4BZCSlM3AMOjFCMP5kU1Z8uTowg9NM= antonio@debian
```

Creo el siguiente fichero ldif `openssh-lpk.ldif`:

```ldif
dn: cn=openssh-lpk,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: openssh-lpk
olcAttributeTypes: ( 1.3.6.1.4.1.24552.500.1.1.1.13 NAME 'sshPublicKey'
  DESC 'MANDATORY: OpenSSH Public key'
  EQUALITY octetStringMatch
  SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )
olcObjectClasses: ( 1.3.6.1.4.1.24552.500.1.1.2.0 NAME 'ldapPublicKey' SUP top AUXILIARY
  DESC 'MANDATORY: OpenSSH LPK objectclass'
  MAY ( sshPublicKey $ uid )
  )
```

Ahora, creo un entorno virtual:

```bash
apt install python3-venv -y
python3 -m venv entorno_ldap
source entorno_ldap/bin/activate
pip install ldap3
```

Y el siguiente programa `ldap_csv.py`:

```python
#!/usr/bin/env python

import ldap3
from ldap3 import Connection, ALL
from getpass import getpass
from sys import exit

### VARIABLES

# Shell que se le asigna a los usuarios
shell = '/bin/bash'

# Ruta absoluta del directorio que contiene los directorios personales de los usuarios. Terminado en "/"
home_dir = '/home/ldap/'

# El valor inicial para los UID que se asignan al insertar usuarios. 
uid_number = 500

# El GID que se le asigna a los usuarios. Si no se manda al anadir el usuario da error.
gid = 500

### VARIABLES

# Leemos el fichero .csv de los usuarios y guardamos cada linea en una lista.
with open('usuarios.csv', 'r') as usuarios:
  usuarios = usuarios.readlines()


### Parametros para la conexion
ldap_ip = 'ldap://alfa.roberto.gonzalonazareno.org:389'
dominio_base = 'dc=roberto,dc=gonzalonazareno,dc=org'
user_admin = 'admin' 
contrasena = getpass('Contrasena: ')

# Intenta realizar la conexion.
conn = Connection(ldap_ip, 'cn={},{}'.format(user_admin, dominio_base),contrasena)

# conn.bind() devuelve "True" si se ha establecido la conexion y "False" en caso contrario.

# Si no se establece la conexion imprime por pantalla un error de conexion.
if not conn.bind():
  print('No se ha podido conectar con ldap') 
  if conn.result['description'] == 'invalidCredentials':
    print('Credenciales no validas.')
  # Termina el script.
  exit(0)

# Recorre la lista de usuarios
for user in usuarios:
  # Separa los valores del usuario usando como delimitador ",", y asigna cada valor a la variable correspondiente.
  user = user.split(',')
  cn = user[0]
  sn = user[1]
  mail = user[2]
  uid = user[3]
  ssh = user[4]

  #Anade el usuario.
  conn.add(
    'uid={},ou=Personas,{}'.format(uid, dominio_base),
    object_class = 
      [
      'inetOrgPerson',
      'posixAccount', 
      'ldapPublicKey'
      ],
    attributes =
      {
      'cn': cn,
      'sn': sn,
      'mail': mail,
      'uid': uid,
      'uidNumber': str(uid_number),
      'gidNumber': str(gid),
      'homeDirectory': '{}{}'.format(home_dir,uid),
      'loginShell': shell,
      'sshPublicKey': str(ssh)
      })

  if conn.result['description'] == 'entryAlreadyExists':
    print('El usuario {} ya existe.'.format(uid))

  # Aumenta el contador para asignar un UID diferente a cada usuario (cada vez que ejecutemos el script debemos asegurarnos de ante mano que no existe dicho uid en el directorio ldap, o se solaparian los datos)
  uid_number += 1

#Cierra la conexion.
conn.unbind()
```

Los ejecuto 

```bash
python3 ldap_csv.py
```

Tras eso, podemos realizar un `ldapsearch` para comprobar que se han añadido los usuarios correctamente:

```bash
ldapsearch -x -D "cn=admin,dc=roberto,dc=gonzalonazareno,dc=org" -b "dc=roberto,dc=gonzalonazareno,dc=org" -W
```

![image-2021033016442](https://i.imgur.com/BZDGSdR.png)

Editamos el fichero `/etc/ldap/ldap.conf`

```bash
BASE dc=roberto,dc=gonzalonazareno,dc=org
URI ldap://roberto.antonio.gonzalonazareno.org
```

en el fichero `/etc/pam.d/common-session` añadimos la siguiente linea al final:

```bash
session    required        pam_mkhomedir.so
```

Ahora creo el siguiente script para encontrar las claves públicas del árbol de LDAP en `/opt/buscarclave.sh` y le damos permiso de ejecución:

```bash
#!/bin/bash

ldapsearch -x -u -LLL -o ldif-wrap=no '(&(objectClass=posixAccount)(uid='"$1"'))' 'sshPublicKey' | sed -n 's/^[ \t]*sshPublicKey::[ \t]*\(.*\)/\1/p' | base64 -d
```

Y le pongo permisos 755:

```bash
chmod 755 /opt/buscarclave.sh
```

Ahora compruebo que funciona:

![clave](https://i.imgur.com/zz3brvp.png)

ahora edito el fichero `/etc/ssh/sshd_config` y reinicio el servicio sshd:

```bash
AuthorizedKeysCommand /opt/buscarclave.sh
AuthorizedKeysCommandUser nobody
```

Ahora tras eso, Antonio puede conectarse con su usuario:

![image-2021033016593](https://i.imgur.com/fZ4nDBJ.jpg)