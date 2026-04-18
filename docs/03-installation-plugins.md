# Partie 3 — Plugins Nagios : Installation et référence complète

## Qu'est-ce qu'un plugin Nagios ?

Un plugin est un **script ou programme exécutable** que Nagios lance pour vérifier l'état
d'un service ou d'une ressource. Chaque plugin retourne un code :

| Code | État | Couleur interface |
|---|---|---|
| 0 | OK | 🟢 Vert |
| 1 | WARNING | 🟡 Jaune |
| 2 | CRITICAL | 🔴 Rouge |
| 3 | UNKNOWN | ⚪ Gris |

Tous les plugins sont installés dans `/usr/local/nagios/libexec/`.

---

## Installation des plugins standards (2.5)

### Télécharger et compiler

```bash
cd /home/nagios/downloads

sudo wget https://nagios-plugins.org/download/nagios-plugins-2.5.tar.gz
sudo tar -zxvf nagios-plugins-2.5.tar.gz
cd nagios-plugins-2.5

sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagcmd
sudo make
sudo make install
```

### Vérifier l'installation

```bash
ls -lh /usr/local/nagios/libexec/
# Doit afficher 50+ plugins
```

---

## 📦 Plugins standards (aucun prérequis supplémentaire)

### 🔵 check_ping
**Usage** : Vérifie qu'un hôte répond au ping (ICMP)

```bash
/usr/local/nagios/libexec/check_ping -H 192.168.1.1 -w 100.0,20% -c 500.0,60%
# PING OK - Packet loss = 0%, RTA = 0.08 ms
```
- `-w` : warning (délai ms, perte %)
- `-c` : critical

---

### 🔵 check_http
**Usage** : Vérifie qu'un serveur web répond correctement

```bash
# Basique
/usr/local/nagios/libexec/check_http -H localhost

# Port spécifique
/usr/local/nagios/libexec/check_http -H localhost -p 8080

# Vérifier un contenu dans la page
/usr/local/nagios/libexec/check_http -H localhost -s "Welcome"

# SSL — alerte si certificat expire dans moins de 30 jours
/usr/local/nagios/libexec/check_http -H monsite.com --ssl -C 30
```

---

### 🔵 check_ssh
**Usage** : Vérifie que le service SSH est accessible

```bash
/usr/local/nagios/libexec/check_ssh -H 192.168.1.10
# SSH OK - OpenSSH_9.2 (protocol 2.0)
```

---

### 🔵 check_disk
**Usage** : Surveille l'espace disque

```bash
# Partition racine
/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /

# Plusieurs partitions
/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /home -p /var
# DISK OK - free space: / 370551 MB (86.02% inode=97%)
```
- `-w` : warning si espace libre < X%
- `-c` : critical si espace libre < X%
- `-p` : partition à vérifier

---

### 🔵 check_load
**Usage** : Surveille la charge CPU (1min, 5min, 15min)

```bash
/usr/local/nagios/libexec/check_load -w 5.0,4.0,3.0 -c 10.0,8.0,6.0
# OK - load average: 0.45, 0.32, 0.28
```

---

### 🔵 check_users
**Usage** : Surveille le nombre d'utilisateurs connectés

```bash
/usr/local/nagios/libexec/check_users -w 5 -c 10
# USERS OK - 0 users currently logged in
```

---

### 🔵 check_procs
**Usage** : Surveille le nombre de processus en cours

```bash
# Nombre total de processus
/usr/local/nagios/libexec/check_procs -w 300 -c 400

# Vérifier qu'apache2 tourne
/usr/local/nagios/libexec/check_procs -C apache2 -w 1: -c 1:
# PROCS OK: 6 processes with command name 'apache2'
```

---

### 🔵 check_swap
**Usage** : Surveille l'utilisation de la mémoire swap

```bash
/usr/local/nagios/libexec/check_swap -w 20% -c 10%
# SWAP OK - 100% free (2047 MB out of 2047 MB)
```

---

### 🔵 check_tcp / check_udp
**Usage** : Vérifie qu'un port TCP/UDP est ouvert

```bash
/usr/local/nagios/libexec/check_tcp -H localhost -p 80
/usr/local/nagios/libexec/check_tcp -H localhost -p 443
/usr/local/nagios/libexec/check_tcp -H localhost -p 22
/usr/local/nagios/libexec/check_udp -H localhost -p 53
```

---

### 🔵 check_dns
**Usage** : Vérifie la résolution DNS

```bash
/usr/local/nagios/libexec/check_dns -H google.com -s 8.8.8.8
# DNS OK: 0.012 seconds response time
```

---

### 🔵 check_smtp
**Usage** : Vérifie qu'un serveur mail SMTP répond

```bash
/usr/local/nagios/libexec/check_smtp -H mail.example.com
# SMTP OK - 0.123 sec. response time
```

---

### 🔵 check_ntp_time
**Usage** : Vérifie la synchronisation de l'horloge NTP

```bash
/usr/local/nagios/libexec/check_ntp_time -H pool.ntp.org -w 0.5 -c 1.0
# NTP OK: Offset 0.002345 secs
```

---

### 🔵 check_ssl_validity
**Usage** : Vérifie la validité d'un certificat SSL

```bash
/usr/local/nagios/libexec/check_ssl_validity -H monsite.com -p 443 -w 30 -c 14
# SSL OK - Certificate 'monsite.com' will expire in 45 days
```

---

### 🔵 check_uptime
**Usage** : Vérifie le temps de fonctionnement du système

```bash
/usr/local/nagios/libexec/check_uptime
# OK: uptime is 2 days 4:32:18
```

---

### 🔵 check_by_ssh
**Usage** : Exécute un check sur une machine distante via SSH (alternative à NRPE)

```bash
/usr/local/nagios/libexec/check_by_ssh \
  -H 192.168.1.50 \
  -l nagios \
  -C "/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /"
```

---

## 📦 Plugins avec prérequis supplémentaires

> Ces plugins nécessitent d'installer une bibliothèque supplémentaire, puis de
> **recompiler** les plugins.

---

### 🟠 check_mysql / check_mysql_query
**Usage** : Surveille une base de données MySQL/MariaDB

**Prérequis** :
```bash
sudo apt-get install -y libmysqlclient-dev
```

**Recompiler** :
```bash
cd /home/nagios/downloads/nagios-plugins-2.5
sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagcmd --with-mysql
sudo make && sudo make install
```

**Utilisation** :
```bash
# Vérifier que MySQL est accessible
/usr/local/nagios/libexec/check_mysql -H localhost -u nagios -p motdepasse

# Vérifier une requête SQL
/usr/local/nagios/libexec/check_mysql_query \
  -H localhost -u nagios -p motdepasse \
  -q "SELECT COUNT(*) FROM users" -w 1000 -c 5000
```

---

### 🟠 check_pgsql
**Usage** : Surveille une base de données PostgreSQL

**Prérequis** :
```bash
sudo apt-get install -y libpq-dev
```

**Recompiler** :
```bash
cd /home/nagios/downloads/nagios-plugins-2.5
sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagcmd --with-pgsql
sudo make && sudo make install
```

---

### 🟠 check_ldap
**Usage** : Surveille un annuaire LDAP / Active Directory

**Prérequis** :
```bash
sudo apt-get install -y libldap2-dev
```

**Recompiler** :
```bash
cd /home/nagios/downloads/nagios-plugins-2.5
sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagcmd
sudo make && sudo make install
```

**Utilisation** :
```bash
/usr/local/nagios/libexec/check_ldap \
  -H ldap.example.com \
  -b "dc=example,dc=com" \
  -w 2 -c 5
```

---

### 🟠 check_disk_smb
**Usage** : Surveille l'espace disque d'un partage réseau Windows (Samba)

**Prérequis** :
```bash
sudo apt-get install -y smbclient
```

**Utilisation** :
```bash
/usr/local/nagios/libexec/check_disk_smb \
  -H 192.168.1.20 \
  -s "Partage" \
  -u "utilisateur" \
  -p "motdepasse" \
  -w 20 -c 10
```

---

### 🟠 check_snmp
**Usage** : Surveille des équipements réseau via SNMP (routeurs, switches, imprimantes)

**Prérequis** :
```bash
sudo apt-get install -y snmp snmpd libnet-snmp-perl
```

**Utilisation** :
```bash
# Vérifier la charge CPU d'un routeur Cisco
/usr/local/nagios/libexec/check_snmp \
  -H 192.168.1.1 \
  -C public \
  -o .1.3.6.1.4.1.2021.10.1.3.1 \
  -w 80 -c 95
```

---

## 📊 Tableau récapitulatif complet

| Plugin | Catégorie | Prérequis | Usage principal |
|---|---|---|---|
| `check_ping` | Réseau | Aucun | Disponibilité hôte |
| `check_http` | Web | Aucun | Site web, SSL |
| `check_ssh` | Réseau | Aucun | Service SSH |
| `check_tcp` | Réseau | Aucun | Port TCP ouvert |
| `check_udp` | Réseau | Aucun | Port UDP ouvert |
| `check_disk` | Système | Aucun | Espace disque |
| `check_load` | Système | Aucun | Charge CPU |
| `check_users` | Système | Aucun | Utilisateurs connectés |
| `check_procs` | Système | Aucun | Processus actifs |
| `check_swap` | Système | Aucun | Mémoire swap |
| `check_dns` | Réseau | Aucun | Résolution DNS |
| `check_smtp` | Mail | Aucun | Serveur SMTP |
| `check_ntp_time` | Système | Aucun | Synchronisation horloge |
| `check_ssl_validity` | Sécurité | Aucun | Certificat SSL |
| `check_uptime` | Système | Aucun | Temps de fonctionnement |
| `check_by_ssh` | Distant | Aucun | Checks distants SSH |
| `check_mysql` | Base de données | `libmysqlclient-dev` | MySQL/MariaDB |
| `check_pgsql` | Base de données | `libpq-dev` | PostgreSQL |
| `check_ldap` | Annuaire | `libldap2-dev` | LDAP/Active Directory |
| `check_disk_smb` | Réseau Windows | `smbclient` | Partages Samba/Windows |
| `check_snmp` | Réseau | `snmp snmpd` | Routeurs, switches |

---

## Tester un plugin manuellement

```bash
# Toujours tester avant d'ajouter à la config Nagios
/usr/local/nagios/libexec/check_ping -H 8.8.8.8 -w 100.0,20% -c 500.0,60%
/usr/local/nagios/libexec/check_http -H google.com
/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /
```

---

## Alias utiles (à ajouter dans ~/.bashrc de primaryos)

```bash
echo "alias testNagios='sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg'" >> ~/.bashrc
echo "alias restartNagios='sudo systemctl restart nagios'" >> ~/.bashrc
echo "alias nagiosLog='sudo tail -f /usr/local/nagios/var/nagios.log'" >> ~/.bashrc
source ~/.bashrc
```

> ⚠️ Toujours ajouter les alias dans `~/.bashrc` de **primaryos**, pas de nagios.
> L'utilisateur nagios utilise `sh` et ne charge pas `.bashrc`.

---

➡️ [Partie 4 — Configuration et interface web](04-configuration-interface.md)
