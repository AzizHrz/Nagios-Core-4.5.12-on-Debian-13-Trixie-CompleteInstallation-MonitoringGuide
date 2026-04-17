# Partie 2 — Compilation et installation de Nagios Core 4.5.12

## Objectif

- Télécharger les sources de Nagios Core 4.5.12
- Compiler depuis les sources
- Installer l'arborescence Nagios
- Configurer l'interface web Apache

---

## 2.1 Télécharger les sources

> ⚠️ **Différence Debian 13** : On utilise **Nagios 4.5.12** (Mars 2026), pas la version 4.4.2
> du cours OpenClassrooms. Toujours vérifier la dernière version sur
> [GitHub Nagios](https://github.com/NagiosEnterprises/nagioscore/releases).

```bash
# Se connecter en tant que nagios
sudo su - nagios

# Aller dans le dossier downloads
cd /home/nagios/downloads

# Télécharger Nagios Core 4.5.12 depuis GitHub
wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.5.12/nagios-4.5.12.tar.gz

# Vérifier le téléchargement
ls -lh nagios-4.5.12.tar.gz
# -rw-r--r-- 1 nagios nagios 2.5M nagios-4.5.12.tar.gz
```

---

## 2.2 Extraire les sources

```bash
tar -zxvf nagios-4.5.12.tar.gz
cd nagios-4.5.12
```

---

## 2.3 Configurer la compilation

```bash
./configure --with-httpd-conf=/etc/apache2/sites-enabled --with-command-group=nagcmd
```

### Résultat attendu

```
*** Configuration summary for nagios 4.5.12 ***

 General Options:
 -------------------------
        Nagios executable:  nagios
        Nagios user/group:  nagios nagios
       Command user/group:  nagios/nagcmd
             Event Broker:  yes
        Install ${prefix}:  /usr/local/nagios
   Install ${includedir}:  /usr/local/nagios/include/nagios
             Lock file:  /run/nagios.lock
   Check result directory:  /usr/local/nagios/var/spool/checkresults
           Init directory:  /lib/systemd/system
  Apache conf.d directory:  /etc/apache2/sites-enabled
             Mail program:  /bin/mail
                  Host OS:  linux-gnu
          IOBroker Method:  epoll

 Web Interface Options:
 ------------------------
                 HTML URL:  http://localhost/nagios/
                  CGI URL:  http://localhost/nagios/cgi-bin/
```

> ⚠️ Le warning `could not find include files` pour Kerberos est **normal** et ignorable.

### Si erreur SSL

```
configure: error: Cannot find ssl headers
```

**Solution** (quitter nagios, installer depuis primaryos) :

```bash
exit  # retour à primaryos
sudo apt-get install libssl-dev -y
sudo su - nagios
cd /home/nagios/downloads/nagios-4.5.12
./configure --with-httpd-conf=/etc/apache2/sites-enabled --with-command-group=nagcmd
```

---

## 2.4 Compiler les sources

```bash
# Toujours en tant que nagios
make all
```

Si la compilation réussit, vous verrez :

```
*** Support Notes ***
...
Enjoy.
```

---

## 2.5 Installer Nagios (avec sudo depuis primaryos)

> ⚠️ **Règle importante** : `make install` écrit dans `/usr/local/nagios/` qui appartient à root.
> Il faut quitter la session nagios et utiliser sudo.

```bash
# Quitter nagios
exit

# Vous êtes maintenant primaryos
cd /home/nagios/downloads/nagios-4.5.12

# Installer les binaires
sudo make install

# Créer les groupes/users système
sudo make install-groups-users

# Ajouter www-data au groupe nagios
sudo usermod -a -G nagios www-data

# Installer le service systemd (démarrage automatique)
sudo make install-daemoninit

# Installer le pipe de commandes
sudo make install-commandmode

# Installer les fichiers de configuration
sudo make install-config

# Installer la configuration Apache
sudo make install-webconf
```

---

## 2.6 Activer les modules Apache

```bash
sudo a2enmod rewrite
sudo a2enmod cgi
```

---

## 2.7 Créer l'utilisateur web Nagios

```bash
sudo htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagiosadmin VotreMotDePasseIci
```

> Remplacez `VotreMotDePasseIci` par un mot de passe sécurisé.

---

## 2.8 Attribuer les droits sur l'arborescence

```bash
sudo chown -R nagios:nagcmd /usr/local/nagios
```

---

## 2.9 Démarrer les services

```bash
# Démarrer et activer Apache
sudo systemctl restart apache2
sudo systemctl enable apache2

# Démarrer et activer Nagios
sudo systemctl enable nagios
sudo systemctl start nagios
```

---

## 2.10 Vérifications

```bash
# Vérifier que Nagios tourne
sudo systemctl status nagios
# Active: active (running) ✅

# Vérifier les processus
ps -edf | grep nagios
# nagios  XXXX  ... /usr/local/nagios/bin/nagios -d ...

# Tester la configuration
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
# Total Warnings: 0
# Total Errors: 0
# Things look okay ✅
```

---

## 2.11 Accéder à l'interface web

Ouvrir un navigateur sur :

```
http://[IP_de_votre_machine]/nagios
```

Login : `nagiosadmin` / mot de passe défini à l'étape 2.7

### Interface attendue

Vous verrez des alertes en rouge de type :
```
No output on stdout) stderr: execvp(/usr/local/nagios/libexec/check_ping,...) 
failed. errno is 2: No such file or directory
```

**C'est normal** — les plugins ne sont pas encore installés. → Partie 3

---

## ✅ Vérification finale Partie 2

```bash
sudo systemctl status nagios    # active (running) ✅
sudo systemctl status apache2   # active (running) ✅
curl http://localhost/nagios     # répond ✅
```

---

➡️ [Partie 3 — Installation des plugins](03-installation-plugins.md)
