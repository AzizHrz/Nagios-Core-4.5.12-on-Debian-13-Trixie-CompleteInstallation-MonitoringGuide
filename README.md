# Nagios Core 4.5.12 — Guide d'installation sur Debian 13.4 (Trixie)

> Guide complet basé sur le cours OpenClassrooms  
> **"Mettez en place un outil de supervision de production avec Nagios"**  
> Adapté et corrigé pour **Debian 13.4 (Trixie)** avec **Nagios Core 4.5.12**

---

##  Table des matières

- [À propos](#-à-propos)
- [Prérequis](#-prérequis)
- [Architecture](#-architecture)
- [Installation rapide (scripts)](#-installation-rapide-scripts)
- [Guide pas à pas](#-guide-pas-à-pas)
  - [Partie 1 — Préparation du serveur](docs/01-preparation-serveur.md)
  - [Partie 2 — Compilation et installation Nagios Core](docs/02-installation-nagios-core.md)
  - [Partie 3 — Installation des plugins](docs/03-installation-plugins.md)
  - [Partie 4 — Configuration et interface web](docs/04-configuration-interface.md)
  - [Partie 5 — Les 4 éléments essentiels : Plugin, Command, Host, Service](docs/05-nagios-core-concepts.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Différences Debian 9 vs Debian 13](#-différences-debian-9-vs-debian-13)
- [Prochaines étapes](#-prochaines-étapes)

---

##  À propos

Ce guide documente une installation **réelle**, réalisée en avril 2026 sur **Debian 13.4 Trixie (bare metal)**.

Il corrige et adapte le cours OpenClassrooms original (écrit pour Debian 9) aux nouvelles versions :

| Composant | Cours original | Ce guide |
|---|---|---|
| OS | Debian 9 Stretch | **Debian 13.4 Trixie** |
| Nagios | 4.4.2 | **4.5.12** |
| PHP | 7.x | **8.4** |
| Plugins | 2.4.6 | **2.5** |

---

##  Prérequis

- Machine physique ou VM sous **Debian 13.4**
- Accès **sudo** sur la machine
- Connexion internet active
- Minimum **2 GB RAM**, **20 GB disque**

---

## Architecture

```
[Debian 13.4 — Nagios Core 4.5.12]
         |
    [Apache2 + PHP 8.4]
         |
    [Interface Web]
    http://[IP]/nagios
         |
   [Réseau local]
   /      |      \
[localhost] [autres PCs] [VM VirtualBox]
```

---

##  Installation rapide (scripts)

```bash
# Cloner le repo
git clone https://github.com/[votre-user]/nagios-debian13-guide.git
cd nagios-debian13-guide

# Étape 1 — Préparer le serveur
sudo bash scripts/01-prepare-server.sh

# Étape 2 — Installer Nagios Core
sudo bash scripts/02-install-nagios-core.sh

# Étape 3 — Installer les plugins
sudo bash scripts/03-install-plugins.sh

# Étape 4 — Configuration finale
sudo bash scripts/04-configure-nagios.sh
```

---

##  Différences Debian 9 vs Debian 13

| Problème | Debian 9 | Debian 13 |
|---|---|---|
| `php-imap` | Disponible directement | Nécessite le dépôt **Sury** → `php8.4-imap` |
| `php-mcrypt` | Disponible | **Obsolète**, à supprimer de la commande |
| `usermod` sans sudo | Fonctionnait |  Nécessite `sudo` explicite |
| SSL headers | Inclus |  Nécessite `libssl-dev` séparé |
| Kerberos | Optionnel |  Warning lors du `./configure` (ignorable) |
| `make install` | En tant que nagios |  Doit être fait avec `sudo` (primaryos) |

---

##  Plugins documentés

### Standards (inclus dans nagios-plugins-2.5)
`check_ping` `check_http` `check_ssh` `check_disk` `check_load` `check_users` `check_procs` `check_swap` `check_tcp` `check_udp` `check_dns` `check_smtp` `check_ntp_time` `check_ssl_validity` `check_uptime` `check_by_ssh`

### Optionnels (prérequis supplémentaires)
`check_mysql` `check_pgsql` `check_ldap` `check_disk_smb` `check_snmp`

```bash
# MySQL seulement
sudo bash scripts/03-install-plugins.sh --with-mysql
# Tout installer
sudo bash scripts/03-install-plugins.sh --with-all
```

---

##  Prochaines étapes

- [ ] Installation des plugins Nagios 2.5 *(en cours)*
- [ ] Configuration NRPE pour monitoring distant
- [ ] Monitoring VM Kali Linux sur VirtualBox
- [ ] Ajout des outils sécurité (Fail2ban, Wazuh)
- [ ] Configuration alertes email

---

## Ressources

- [Cours OpenClassrooms](https://openclassrooms.com/fr/courses/2035786-mettez-en-place-un-outil-de-supervision-de-production-avec-nagios)
- [Nagios Core officiel](https://www.nagios.org/projects/nagios-core/)
- [GitHub Nagios Core](https://github.com/NagiosEnterprises/nagioscore)
- [Dépôt PHP Sury](https://packages.sury.org/php/)
