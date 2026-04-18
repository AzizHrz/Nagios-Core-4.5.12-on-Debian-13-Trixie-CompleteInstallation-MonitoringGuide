# Partie 5 — Les 4 éléments essentiels de Nagios

## Vue d'ensemble

Nagios fonctionne autour de **4 objets fondamentaux** qui s'articulent ensemble :

```
Plugin  →  Command  →  Service  →  Host
  ↑           ↑           ↑          ↑
programme   comment    quoi         sur qui
exécutable  lancer     surveiller   surveiller
```

---

## 1️⃣ Le Plugin

Un plugin est un **programme exécutable** que Nagios lance pour effectuer une vérification.
Il peut s'agir d'un binaire compilé en C, d'un script Perl, d'un script Bash, etc.

```
/usr/local/nagios/libexec/check_ping
/usr/local/nagios/libexec/check_http
/usr/local/nagios/libexec/check_ssh
```

Le plugin retourne toujours un code :

| Code | État | Signification |
|---|---|---|
| 0 | OK | Tout va bien 🟢 |
| 1 | WARNING | Attention ⚠️ |
| 2 | CRITICAL | Problème critique 🔴 |
| 3 | UNKNOWN | Résultat inconnu ⚪ |

---

## 2️⃣ La Command

La **command** est un objet Nagios qui définit **comment lancer un plugin**.
Elle fait le lien entre Nagios et le plugin.

Fichier : `/usr/local/nagios/etc/objects/commands.cfg`

### Syntaxe

```cfg
define command {
    command_name    check_ssh
    command_line    $USER1$/check_ssh $ARG1$ $HOSTADDRESS$
}
```

| Variable | Signification |
|---|---|
| `$USER1$` | Chemin vers `/usr/local/nagios/libexec/` |
| `$HOSTADDRESS$` | L'adresse IP ou nom de l'hôte |
| `$ARG1$`, `$ARG2$` | Arguments passés depuis le service |

### Exemple réel — check-ssh-localhost (depuis nos screenshots)

Dans notre installation, nous avons ajouté une command custom pour SSH sur localhost :

```cfg
define command {
    command_name    check-ssh-localhost
    command_line    $USER1$/check_ssh localhost
}
```

> Cette command est spécialisée pour vérifier SSH **sur le serveur Nagios lui-même**,
> sans passer l'adresse en paramètre.

### Exemple — check_ping avec fix IPv4

```cfg
define command {
    command_name    check_ping
    command_line    $USER1$/check_ping -H $HOSTADDRESS$ -w $ARG1$ -c $ARG2$ -4
}

define command {
    command_name    check-host-alive
    command_line    $USER1$/check_ping -H $HOSTADDRESS$ -w 3000.0,80% -c 5000.0,100% -p 5 -4
}
```

> ⚠️ Le `-4` force IPv4 — indispensable si votre connexion (hotspot iPhone, etc.)
> ne supporte pas IPv6.

---

## 3️⃣ Le Host

Un **host** représente un équipement réseau à superviser : serveur, PC, routeur, imprimante...
Il possède généralement une adresse IP et répond au ping ICMP.

Fichier : `/usr/local/nagios/etc/objects/localhost.cfg`

### Syntaxe complète

```cfg
define host {
    use                 linux-server    ; Template à utiliser
    host_name           localhost       ; Nom unique de l'hôte
    alias               localhost       ; Nom affiché dans l'interface
    address             127.0.0.1       ; Adresse IP
}
```

### Exemple réel — Nagios Server (depuis nos screenshots)

Nous avons ajouté le **serveur Nagios lui-même** comme hôte à surveiller :

```cfg
define host {
    host_name           Nagios Server
    address             localhost
    check_command       check-host-alive
    max_check_attempts  3
    contacts            nagiosadmin
}
```

> Résultat dans l'interface :
> - **2 hosts** visibles : `localhost` et `Nagios Server`
> - Les deux affichent **UP** avec PING OK ✅

### Résultat dans l'interface web

```
Host Status Details For All Host Groups
Host            Status   Last Check           Status Information
Nagios Server   UP  ✅   04-18-2026 14:46:40  PING OK - Packet loss = 0%, RTA = 0.12 ms
localhost       UP  ✅   04-18-2026 14:45:36  PING OK - Packet loss = 0%, RTA = 0.13 ms
```

---

## 4️⃣ Le Service

Un **service** représente une donnée à surveiller **sur un host** :
- Un service réseau (port SSH, HTTP, DNS...)
- Une ressource système (CPU, RAM, disque...)
- N'importe quelle vérification associée à un hôte

Fichier : `/usr/local/nagios/etc/objects/localhost.cfg`

### Syntaxe complète

```cfg
define service {
    use                     local-service   ; Template
    host_name               localhost       ; Hôte concerné
    service_description     SSH             ; Nom affiché
    check_command           check_ssh       ; Command à utiliser
    max_check_attempts      4
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_period     24x7
    contacts                nagiosadmin
}
```

### Exemple réel — SSH in Nagios Server (depuis nos screenshots)

Nous avons ajouté un service pour surveiller SSH **sur le serveur Nagios** :

```cfg
define service {
    host_name               Nagios Server
    service_description     SSH in Nagios Server
    check_command           check-ssh-localhost
    max_check_attempts      3
    contacts                nagiosadmin
    check_period            24x2
    notification_period     24x7
}
```

> Résultat dans l'interface :
> ```
> Service: SSH in Nagios Server
> Current Status: OK ✅
> Status Information: SSH OK - OpenSSH_10.0p2 Debian-7+deb13u2 (protocol 2.0)
> ```

### Tous les services monitorés (depuis nos screenshots)

```
Host            Service              Status   Status Information
Nagios Server   SSH in Nagios Server OK ✅    SSH OK - OpenSSH_10.0p2
localhost       Current Load         OK ✅    OK - load average: 0.81, 0.44, 0.33
localhost       Current Users        OK ✅    USERS OK - 0 users currently logged in
localhost       HTTP                 OK ✅    HTTP OK: HTTP/1.1 200 OK
localhost       PING                 OK ✅    PING OK - Packet loss = 0%, RTA = 0.13 ms
localhost       Root Partition       OK ✅    DISK OK - free space: / 370384 MB
localhost       SSH                  OK ✅    SSH OK - OpenSSH_10.0p2
localhost       Swap Usage           OK ✅    SWAP OK - 100% free (25182 MB)
localhost       Total Processes      OK ✅    PROCS OK: 183 processes
```

---

## 🔄 Workflow complet — Ajouter un nouvel élément à superviser

Voici le processus **à chaque fois** que tu veux ajouter quelque chose à Nagios :

```
Étape 1 : Tester le plugin manuellement
    cd /usr/local/nagios/libexec
    ./check_ssh localhost
    → SSH OK ✅ (plugin fonctionne)

Étape 2 : Définir la Command (si elle n'existe pas)
    sudo nano /usr/local/nagios/etc/objects/commands.cfg
    → Ajouter le define command { ... }

Étape 3 : Définir le Host (si l'hôte n'existe pas)
    sudo nano /usr/local/nagios/etc/objects/localhost.cfg
    → Ajouter le define host { ... }

Étape 4 : Définir le Service
    sudo nano /usr/local/nagios/etc/objects/localhost.cfg
    → Ajouter le define service { ... }

Étape 5 : Toujours tester avant de recharger !
    testNagios
    → Total Errors: 0 ✅

Étape 6 : Recharger Nagios
    restartNagios
```

---

## ⚠️ Erreur fréquente — Command non définie

### Symptôme (depuis nos screenshots)

```
Error: Service check command 'check-ssh-localhost' specified in service
'SSH in Nagios Server' for host 'Nagios Server' not defined anywhere!
Total Errors: 1
```

### Cause

Le service référence une command `check-ssh-localhost` qui n'existe pas encore
dans `commands.cfg`.

### Solution

```bash
sudo nano /usr/local/nagios/etc/objects/commands.cfg
```

Ajouter :

```cfg
define command {
    command_name    check-ssh-localhost
    command_line    $USER1$/check_ssh localhost
}
```

```bash
testNagios     # Vérifier → Total Errors: 0
restartNagios  # Recharger
```

---

## SSH — Activer le service avant de le surveiller

Avant de pouvoir monitorer SSH, le service doit être **installé et actif** sur la machine.

```bash
# Installer OpenSSH server
sudo apt-get install openssh-server -y

# Démarrer et activer
sudo systemctl start ssh
sudo systemctl enable ssh

# Vérifier
sudo systemctl status ssh
# Active: active (running) ✅

# Tester le plugin
/usr/local/nagios/libexec/check_ssh localhost
# SSH OK - OpenSSH_10.0p2 Debian-7+deb13u2 (protocol 2.0) ✅
```

---

➡️ [Troubleshooting](TROUBLESHOOTING.md)
