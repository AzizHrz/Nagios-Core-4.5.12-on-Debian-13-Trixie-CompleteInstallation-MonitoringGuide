# Partie 4 — Configuration et interface web

## Objectif

- Comprendre l'interface web Nagios
- Tester la configuration
- Vérifier le monitoring du localhost

---

## 4.1 Tester la configuration Nagios

```bash
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
```

Résultat attendu :

```
Nagios Core 4.5.12

Reading configuration data...
   Read main config file okay...
   Read object config files okay...

Running pre-flight check on configuration data...

Checking objects...
        Checked 8 services.
        Checked 1 hosts.
        Checked 1 host groups.
        Checked 0 service groups.
        Checked 1 contacts.
        Checked 1 contact groups.
        Checked 24 commands.
        Checked 5 time periods.

Total Warnings: 0
Total Errors:   0

Things look okay — No serious problems were detected during the pre-flight check ✅
```

---

## 4.2 Accéder à l'interface web

```
http://[IP_machine]/nagios
```

Login : `nagiosadmin` / votre mot de passe

---

## 4.3 Comprendre l'interface

### Menu principal

| Section | Description |
|---|---|
| **Home** | Page d'accueil |
| **Tactical Overview** | Vue globale de l'état du monitoring |
| **Hosts** | Liste des hôtes monitorés |
| **Services** | Liste des services monitorés |
| **Host Groups** | Groupes d'hôtes |
| **Problems → Services** | Services en erreur |
| **Problems → Hosts** | Hôtes en erreur |
| **Reports → Alerts** | Historique des alertes |
| **System → Configuration** | Configuration Nagios |

---

## 4.4 Alias utile pour tester la configuration

Ajouter un alias dans `.bashrc` de primaryos pour tester facilement la config :

```bash
# Méthode correcte avec tee (évite le problème sudo + >>)
echo "alias testNagios='sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg'" \
  | sudo tee -a /home/nagios/.bashrc

# Recharger
source /home/nagios/.bashrc

# Utiliser
testNagios
```

---

## 4.5 Commandes utiles au quotidien

```bash
# Statut des services
sudo systemctl status nagios
sudo systemctl status apache2

# Redémarrer après modification de config
sudo systemctl reload nagios

# Voir les logs en temps réel
sudo tail -f /usr/local/nagios/var/nagios.log

# Vérifier la config avant redémarrage
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
```

---

## 4.6 Arborescence Nagios

```
/usr/local/nagios/
├── bin/          → Binaires (nagios, nagiostats)
├── etc/          → Fichiers de configuration
│   ├── nagios.cfg          → Config principale
│   ├── cgi.cfg             → Config interface web
│   ├── htpasswd.users      → Utilisateurs web
│   └── objects/
│       ├── commands.cfg    → Commandes de check
│       ├── contacts.cfg    → Contacts pour alertes
│       ├── localhost.cfg   → Config du localhost
│       ├── templates.cfg   → Templates réutilisables
│       └── timeperiods.cfg → Périodes de surveillance
├── libexec/      → Plugins (check_ping, check_http...)
├── sbin/         → Scripts CGI pour l'interface web
├── share/        → Fichiers web (HTML, CSS, JS)
└── var/          → Données runtime
    ├── nagios.log          → Fichier de logs principal
    └── rw/                 → Pipe de commandes
```

---

➡️ [Troubleshooting](TROUBLESHOOTING.md)
