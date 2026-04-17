# Partie 1 — Préparation du serveur Debian 13.4

## Objectif

Préparer l'environnement système pour accueillir Nagios Core :
- Installer Apache2, PHP 8.4 et les dépendances
- Créer l'utilisateur et les groupes Nagios
- Préparer l'arborescence de travail

---

## 1.1 Mise à jour du système

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 1.2 Installer Apache2, PHP et les dépendances

> ⚠️ **Différence Debian 13** : `php-imap` et `php-mcrypt` ne sont plus disponibles directement.

### Installer Apache2 + PHP de base

```bash
sudo apt-get install apache2 php php-gd php-curl -y
```

### Ajouter le dépôt Sury pour php-imap

Sur Debian 13 (Trixie), `php-imap` nécessite le dépôt officiel PHP de Sury :

```bash
# Installer les prérequis
sudo apt-get install apt-transport-https lsb-release ca-certificates curl -y

# Ajouter la clé GPG
sudo curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg \
  https://packages.sury.org/php/apt.gpg

# Ajouter le dépôt
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] \
  https://packages.sury.org/php/ $(lsb_release -sc) main" \
  > /etc/apt/sources.list.d/php.list'

# Mettre à jour
sudo apt-get update

# Installer php8.4-imap (et non php-imap)
sudo apt-get install php8.4-imap -y
```

### Vérification PHP

```bash
php -m | grep -E "gd|imap|curl"
# Résultat attendu :
# curl
# gd
# imap
```

---

## 1.3 Installer les bibliothèques Perl

```bash
sudo apt-get install -y \
  libxml-libxml-perl \
  libnet-snmp-perl \
  libperl-dev \
  libnumber-format-perl \
  libconfig-inifiles-perl \
  libdatetime-perl \
  libnet-dns-perl
```

---

## 1.4 Installer les bibliothèques graphiques et de compilation

```bash
sudo apt-get install -y \
  libpng-dev \
  libjpeg-dev \
  libgd-dev \
  gcc \
  make \
  autoconf \
  libc6 \
  unzip \
  libssl-dev \
  libkrb5-dev \
  build-essential \
  bc \
  gawk \
  dc \
  libapache2-mod-php \
  snmp \
  libnet-snmp-perl \
  gettext
```

> ⚠️ **Différence Debian 13** : `libssl-dev` est **obligatoire** sinon `./configure` échoue avec :
> `configure: error: Cannot find ssl headers`

---

## 1.5 Créer l'utilisateur et les groupes Nagios

```bash
# Créer l'utilisateur nagios avec home directory
sudo useradd -m nagios

# Définir le mot de passe de façon sécurisée (interactive)
sudo passwd nagios
# Entrer un mot de passe fort

# Créer le groupe nagcmd
sudo groupadd nagcmd

# Ajouter nagios et www-data au groupe nagcmd
sudo usermod -a -G nagcmd nagios
sudo usermod -a -G nagcmd www-data
```

---

## 1.6 Préparer le répertoire de travail

```bash
# Créer le dossier downloads AVEC les bonnes permissions
sudo mkdir /home/nagios/downloads

# Attribuer la propriété à l'utilisateur nagios
sudo chown -R nagios:nagios /home/nagios/
sudo chmod 755 /home/nagios/
```

> ⚠️ **Problème fréquent Debian 13** : si `mkdir` est fait avec `sudo`, le dossier appartient
> à `root`. Il faut **toujours** faire `chown` après.

### Vérification

```bash
ls -la /home/nagios/
# Résultat attendu :
# drwxr-xr-x  nagios nagios  downloads/
# -rw-r--r--  nagios nagios  .bashrc
```

---

## ✅ Vérification finale Partie 1

```bash
apache2 -v       # Version Apache
php -v           # PHP 8.4.x
gcc --version    # GCC installé
make --version   # Make installé
id nagios        # Utilisateur nagios créé
groups nagios    # nagios nagcmd
```

---

➡️ [Partie 2 — Compilation et installation Nagios Core](02-installation-nagios-core.md)
