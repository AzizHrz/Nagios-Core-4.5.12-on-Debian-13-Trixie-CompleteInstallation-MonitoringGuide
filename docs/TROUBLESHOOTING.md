# 🔧 Troubleshooting — Problèmes rencontrés et solutions

Tous les problèmes ci-dessous ont été rencontrés lors de l'installation réelle sur
**Debian 13.4 Trixie** en avril 2026.

---

## ❌ Problème 1 — Permission denied sur apt-get

### Symptôme

```
E: Could not open lock file /var/lib/dpkg/lock-frontend - open (13: Permission denied)
E: Unable to acquire the dpkg frontend lock, are you root?
```

### Cause

La commande `apt-get` a été lancée sans `sudo`.

### Solution

```bash
sudo apt-get install [packages]
```

---

## ❌ Problème 2 — php-imap introuvable

### Symptôme

```
E: Package 'php-imap' has no installation candidate
```

### Cause

Sur Debian 13 avec PHP 8.4, le paquet `php-imap` générique n'existe plus. Il faut utiliser
le paquet versionné `php8.4-imap` depuis le dépôt Sury.

### Solution

```bash
# Ajouter le dépôt Sury
sudo apt-get install apt-transport-https lsb-release ca-certificates curl -y

sudo curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg \
  https://packages.sury.org/php/apt.gpg

sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] \
  https://packages.sury.org/php/ $(lsb_release -sc) main" \
  > /etc/apt/sources.list.d/php.list'

sudo apt-get update
sudo apt-get install php8.4-imap -y
```

### Vérification

```bash
php -m | grep imap
# imap ✅
```

---

## ❌ Problème 3 — php-common : Breaks php-imap

### Symptôme

```
The following packages have unmet dependencies:
 php-common : Breaks: php-imap (< 3:1.0.3-1)
              Breaks: php8.3-common
E: Error, pkgProblemResolver::Resolve generated breaks
```

### Cause

Conflit entre la version générique `php-imap` (trop ancienne) et `php-common` qui requiert
`php8.4`. Les deux versions de PHP entrent en conflit.

### Solution

Ne pas mélanger `php-imap` (générique) et `php8.4-*` (versionné). Utiliser **uniquement**
les paquets versionnés du dépôt Sury :

```bash
# ❌ Ne pas faire
sudo apt-get install php-imap

# ✅ Faire à la place
sudo apt-get install php8.4-imap
```

---

## ❌ Problème 4 — cannot find ssl headers

### Symptôme

```
checking for SSL headers... configure: error: Cannot find ssl headers
```

### Cause

La bibliothèque de développement OpenSSL (`libssl-dev`) n'est pas installée.
La différence est :
- `openssl` : l'outil binaire uniquement
- `libssl-dev` : les fichiers `.h` nécessaires pour **compiler**

### Solution

```bash
exit  # Quitter la session nagios
sudo apt-get install libssl-dev -y
sudo su - nagios
cd /home/nagios/downloads/nagios-4.5.12
./configure --with-httpd-conf=/etc/apache2/sites-enabled --with-command-group=nagcmd
```

---

## ❌ Problème 5 — Warning Kerberos lors du configure

### Symptôme

```
checking for Kerberos include files... configure: WARNING: could not find include files
```

### Cause

Kerberos (protocole d'authentification) n'est pas installé.

### Solution

Ce n'est qu'un **warning**, pas une erreur bloquante. Deux options :

**Option A** — Ignorer (acceptable pour un lab) : continuer avec `make all`

**Option B** — Installer Kerberos pour supprimer le warning :

```bash
exit
sudo apt-get install libkrb5-dev -y
sudo su - nagios
cd /home/nagios/downloads/nagios-4.5.12
./configure --with-httpd-conf=/etc/apache2/sites-enabled --with-command-group=nagcmd
```

---

## ❌ Problème 6 — make install : Permission denied sur /usr/local/nagios

### Symptôme

```
install: cannot create directory '/usr/local/nagios': Permission denied
make[1]: *** [Makefile:187: install] Error 1
```

### Cause

`make install` doit créer des dossiers dans `/usr/local/` qui appartient à `root`.
L'utilisateur `nagios` n'a pas ces droits.

### Règle à retenir

| Commande | Utilisateur | Pourquoi |
|---|---|---|
| `./configure` | nagios | Lit seulement le système |
| `make all` | nagios | Compile dans le dossier local |
| `make install` | **sudo (primaryos)** | Écrit dans `/usr/local/` |

### Solution

```bash
exit  # Quitter nagios → retour à primaryos
cd /home/nagios/downloads/nagios-4.5.12
sudo make install
```

---

## ❌ Problème 7 — usermod : command not found

### Symptôme

```
bash: usermod: command not found
```

### Cause

La commande a été lancée sans `sudo`. `usermod` est une commande système qui nécessite
les droits root.

### Solution

```bash
sudo usermod -a -G nagcmd nagios
sudo usermod -a -G nagcmd www-data
```

---

## ❌ Problème 8 — cd avec sudo

### Symptôme

```
sudo: cd: command not found
sudo: "cd" is a shell built-in command, it cannot be run directly.
```

### Cause

`cd` est une **commande interne du shell** (builtin). Elle ne peut jamais être préfixée
par `sudo` car elle n'existe pas comme programme externe.

### Solution

Corriger d'abord les permissions du dossier, puis faire `cd` normalement :

```bash
sudo chown -R nagios:nagios /home/nagios/
cd /home/nagios/downloads  # sans sudo
```

---

## ❌ Problème 9 — Permission denied sur /home/nagios/downloads

### Symptôme

```
nagios-4.5.12.tar.gz: Permission denied
Cannot write to 'nagios-4.5.12.tar.gz' (Permission denied).
```

### Cause

Le dossier `/home/nagios/downloads` a été créé avec `sudo mkdir` et appartient donc
à `root`, pas à l'utilisateur `nagios`.

### Solution

```bash
exit  # retour à primaryos
sudo chown -R nagios:nagios /home/nagios/
sudo chmod 755 /home/nagios/

# Vérifier
ls -la /home/nagios/
# drwxr-xr-x  nagios nagios  downloads/ ✅
```

---

## ❌ Problème 10 — echo >> avec sudo ne fonctionne pas

### Symptôme

```bash
sudo echo "alias testNagios=..." >> /home/nagios/.bashrc
bash: /home/nagios/.bashrc: Permission denied
```

### Cause

La redirection `>>` est gérée par le **shell de l'utilisateur courant**, pas par sudo.
Même avec `sudo echo`, c'est le shell (primaryos) qui essaie d'ouvrir le fichier, et
il n'a pas les droits.

```
sudo echo "x" >> fichier
  ↑              ↑
sudo appliqué   >> géré par le shell sans sudo
à echo only
```

### Solutions

```bash
# Solution 1 — tee (recommandée)
echo "alias testNagios='...'" | sudo tee -a /home/nagios/.bashrc

# Solution 2 — bash -c
sudo bash -c 'echo "alias testNagios=..." >> /home/nagios/.bashrc'

# Solution 3 — se connecter en nagios
sudo su - nagios
echo "alias testNagios='...'" >> ~/.bashrc
exit
```

---

## ❌ Problème 11 — nagios not in sudoers

### Symptôme

```
nagios is not in the sudoers file.
```

### Cause

L'utilisateur `nagios` est un compte système de service. Il n'a pas (et ne devrait pas avoir)
les droits sudo.

### Bonne pratique

Ne **pas** ajouter `nagios` au groupe sudo. Toutes les commandes privilégiées doivent être
exécutées depuis **primaryos** (votre compte admin) avec `sudo`.

```
primaryos (sudo)  →  commandes système, installation, démarrage services
nagios            →  compilation des sources uniquement (./configure, make all)
```

---

## ❌ Problème 12 — Lien de téléchargement Nagios 404

### Symptôme

```
ERROR 404: Not Found
```
lors du téléchargement depuis `assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.2.tar.gz`

### Cause

Le lien du cours OpenClassrooms est obsolète (version 4.4.2, 2018).

### Solution

Toujours télécharger depuis **GitHub** (lien permanent) :

```bash
wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.5.12/nagios-4.5.12.tar.gz
```

Vérifier la dernière version sur : https://github.com/NagiosEnterprises/nagioscore/releases

---

## ❌ Problème 13 — tar : Permission denied lors de l'extraction

### Symptôme

```
tar: nagios-plugins-2.5: Cannot mkdir: Permission denied
```

### Cause

L'archive a été téléchargée avec `sudo wget` dans un répertoire qui appartient à `root`.

### Solution

```bash
# Télécharger depuis primaryos (pas en nagios)
cd /home/nagios/downloads
sudo wget [url]
sudo tar -zxvf nagios-plugins-2.5.tar.gz  # avec sudo
```

---

## 📊 Résumé des règles à retenir

| Commande | Utilisateur correct |
|---|---|
| `apt-get install` | `sudo` (primaryos) |
| `./configure` | `nagios` ou `sudo` |
| `make all` | `nagios` |
| `make install` | `sudo` (primaryos) |
| `systemctl` | `sudo` (primaryos) |
| `a2enmod` | `sudo` (primaryos) |
| `chown`, `chmod` | `sudo` (primaryos) |
| `cd` | **jamais** avec sudo |
| `echo >>` | via `tee -a` avec sudo |
