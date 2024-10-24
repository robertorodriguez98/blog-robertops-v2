---
title: Instalación de MariaDB y PostgreSQL en Debian
published: 2022-10-26
image: "./featured.png"
tags: ["MySQL", "apache","phpMyAdmin"]
category: Práctica
draft: false
---

## MariaDB

El paquete de MariaDB se encuentra en los repositorios de Debian, por lo que podemos instalarlo directamente con apt:

```bash
sudo apt update
sudo apt install mariadb-server -y 
```

Entramos en la base de datos como root:

```bash
mysql -u root -p
```

### Configuración para acceso remoto

Para poder acceder remotamente tenemos que modificar el archivo de configuración `/etc/mysql/mariadb.conf.d/50-server.cnf`, buscando la línea de **bind-address** y poniendo lo siguiente:

```bash
bind-address            = 0.0.0.0
```

A continuación reiniciamos el servicio de mariadb:

```bash
systemctl restart mariadb.service
```

Dentro de mariadb, tenemos que crear un usuario para el acceso remoto (el `%` es un comodín para indicar que se pueda acceder desde cualquier dirección):

```sql
GRANT ALL PRIVILEGES ON *.* TO 'remoto'@'%'
IDENTIFIED BY 'remoto' WITH GRANT OPTION;
```

### Creación de usuario

Creamos un usuario con todos los privilegios:

```bash
GRANT ALL PRIVILEGES ON *.* TO 'roberto'@'localhost'
IDENTIFIED BY 'roberto' WITH GRANT OPTION;
```

Ahora podemos entrar con el usuario roberto:

```bash
mysql -u roberto -p
```

### Creación de tablas

Vamos a crear el esquema scott en mysql:

```sql
create database scott;
use scott;
```

```sql
CREATE TABLE IF NOT EXISTS `dept` (
  `DEPTNO` int(11) DEFAULT NULL,
  `DNAME` varchar(14) DEFAULT NULL,
  `LOC` varchar(13) DEFAULT NULL
);
INSERT INTO `dept` (`DEPTNO`, `DNAME`, `LOC`) VALUES
(10, 'ACCOUNTING', 'NEW YORK'),
(20, 'RESEARCH', 'DALLAS'),
(30, 'SALES', 'CHICAGO'),
(40, 'OPERATIONS', 'BOSTON');
CREATE TABLE IF NOT EXISTS `emp` (
  `EMPNO` int(11) NOT NULL,
  `ENAME` varchar(10) DEFAULT NULL,
  `JOB` varchar(9) DEFAULT NULL,
  `MGR` int(11) DEFAULT NULL,
  `HIREDATE` date DEFAULT NULL,
  `SAL` int(11) DEFAULT NULL,
  `COMM` int(11) DEFAULT NULL,
  `DEPTNO` int(11) DEFAULT NULL
);
INSERT INTO `emp` (`EMPNO`, `ENAME`, `JOB`, `MGR`, `HIREDATE`, `SAL`, `COMM`, `DEPTNO`) VALUES
(7369, 'SMITH', 'CLERK', 7902, '1980-12-17', 800, NULL, 20),
(7499, 'ALLEN', 'SALESMAN', 7698, '1981-02-20', 1600, 300, 30),
(7521, 'WARD', 'SALESMAN', 7698, '1981-02-22', 1250, 500, 30),
(7566, 'JONES', 'MANAGER', 7839, '1981-04-02', 2975, NULL, 20),
(7654, 'MARTIN', 'SALESMAN', 7698, '1981-09-28', 1250, 1400, 30),
(7698, 'BLAKE', 'MANAGER', 7839, '1981-05-01', 2850, NULL, 30),
(7782, 'CLARK', 'MANAGER', 7839, '1981-06-09', 2450, NULL, 10),
(7788, 'SCOTT', 'ANALYST', 7566, '1982-12-09', 3000, NULL, 20),
(7839, 'KING', 'PRESIDENT', NULL, '1981-11-17', 5000, NULL, 10),
(7844, 'TURNER', 'SALESMAN', 7698, '1980-09-08', 1500, 0, 30),
(7876, 'ADAMS', 'CLERK', 7788, '1983-01-12', 1100, NULL, 20),
(7900, 'JAMES', 'CLERK', 7698, '1981-12-03', 950, NULL, 30),
(7902, 'FORD', 'ANALYST', 7566, '1981-12-03', 3000, NULL, 20),
(7934, 'MILLER', 'CLERK', 7782, '1982-01-23', 1300, NULL, 10);
```

## PostgreSQL

El paquete de PostgreSQL se encuentra en los repositorios de Debian, por lo que podemos instalarlo directamente con apt:

```bash
sudo apt install postgreSQL
```

Accedemos al usuario postgres:

```bash
su postgres
```

### Configuración para acceso remoto

Para poder acceder remotamente tenemos que modificar el archivo de configuración `/etc/postgresql/13/main/postgresql.conf`, buscando la línea de **listen_addresses** y poniendo lo siguiente:

```bash
listen_addresses = '*'
```

También, al final del fichero `/etc/postgresql/13/main/pg_hba.conf` tenemos que añadir las siguientes líneas:

```bash
host    all      all              0.0.0.0/0                    md5
host    all      all              ::/0                         md5
```

Reiniciamos el servicio para que los cambios tengan efecto:

```bash
systemctl restart postgresql.service
```

Ahora vamos a crear un usuario con contraseña para acceder desde fuera con el siguiente comando dentro de `psql`:

```sql
create user roberto with superuser password 'roberto';
```

### Creación de tablas

Creamos la base de datos y accedemos a `psql`

```bash
createdb scott
psql
```

Dentro del intérprete de comandos añadimos el esquema scott:

```sql
\c scott

create table dept (
  deptno integer,
  dname  text,
  loc    text,
  constraint pk_dept primary key (deptno)
);
create table emp (
  empno    integer,
  ename    text,
  job      text,
  mgr      integer,
  hiredate date,
  sal      integer,
  comm     integer,
  deptno   integer,
  constraint pk_emp primary key (empno),
  constraint fk_mgr foreign key (mgr) references emp (empno),
  constraint fk_deptno foreign key (deptno) references dept (deptno)
);
insert into dept (deptno,  dname,        loc)
       values    (10,     'ACCOUNTING', 'NEW YORK'),
                 (20,     'RESEARCH',   'DALLAS'),
                 (30,     'SALES',      'CHICAGO'),
                 (40,     'OPERATIONS', 'BOSTON');
insert into emp (empno, ename,    job,        mgr,   hiredate,     sal, comm, deptno)
       values   (7369, 'SMITH',  'CLERK',     7902, '1980-12-17',  800, NULL,   20),
                (7499, 'ALLEN',  'SALESMAN',  7698, '1981-02-20', 1600,  300,   30),
                (7521, 'WARD',   'SALESMAN',  7698, '1981-02-22', 1250,  500,   30),
                (7566, 'JONES',  'MANAGER',   7839, '1981-04-02', 2975, NULL,   20),
                (7654, 'MARTIN', 'SALESMAN',  7698, '1981-09-28', 1250, 1400,   30),
                (7698, 'BLAKE',  'MANAGER',   7839, '1981-05-01', 2850, NULL,   30),
                (7782, 'CLARK',  'MANAGER',   7839, '1981-06-09', 2450, NULL,   10),
                (7788, 'SCOTT',  'ANALYST',   7566, '1982-12-09', 3000, NULL,   20),
                (7839, 'KING',   'PRESIDENT', NULL, '1981-11-17', 5000, NULL,   10),
                (7844, 'TURNER', 'SALESMAN',  7698, '1981-09-08', 1500,    0,   30),
                (7876, 'ADAMS',  'CLERK',     7788, '1983-01-12', 1100, NULL,   20),
                (7900, 'JAMES',  'CLERK',     7698, '1981-12-03',  950, NULL,   30),
                (7902, 'FORD',   'ANALYST',   7566, '1981-12-03', 3000, NULL,   20),
                (7934, 'MILLER', 'CLERK',     7782, '1982-01-23', 1300, NULL,   10);
```

## MongoDB

Como indica la [documentación oficial](https://www.mongodb.com/docs/v6.0/tutorial/install-mongodb-on-debian/), Primero tenemos que añadir la clave a nuestros repositorios:

```bash
sudo apt install gnupg gnupg2 gnupg1
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
```

Ahora añadimos el repositorio de mongo a los repositorios de debian:

```bash
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/6.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
```

Y ahora, con los repositorios ya añadidos, instalamos mongodb:

```bash
sudo apt update
sudo apt install -y mongodb-org
```

Una vez instalado, iniciamos el servicio y activamos el inicio automático:

```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```

### Configuración de acceso remoto

Tenemos que editar el fichero `/etc/mongod.conf` y comentar la línea `bindIP`:

```bash
# bindIp: 127.0.0.1
```

y reiniciamos el servicio

```bash
sudo systemctl restart mongod
```

### Creación de documentos

En este caso voy a insertar los datos de mi [proyecto de MongoDB](https://github.com/robertorodriguez98/proyectoMongoDB/)

```bash
mongoimport --db=yugioh --collection=prankkids --jsonArray --type json --file=prankkids.json
```

Podemos hacer una consulta para comprobar que se ha creado correctamente:

```sql
use yugioh
db.prankkids.find({"card_sets.set_name":"Hidden Summoners"}).count()
```

![mongo](mongo.png)