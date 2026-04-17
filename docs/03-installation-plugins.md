# Partie 3 — Installation des plugins Nagios 2.5

## Objectif

Installer les plugins standards de Nagios qui permettent d'effectuer les vérifications :
`check_ping`, `check_http`, `check_disk`, `check_ssh`, etc.

> 📌 *Cette partie est en cours de documentation. Les plugins ont été installés avec succès
> (voir screenshots). La documentation détaillée sera complétée dans la prochaine mise à jour.*

---

## 3.1 Télécharger les plugins

```bash
# Depuis primaryos (les permissions sont correctes)
cd /home/nagios/downloads

sudo wget https://nagios-plugins.org/download/nagios-plugins-2.5.tar.gz

# Vérifier
ls -lh nagios-plugins-2.5.tar.gz
```

> ⚠️ **Problème fréquent** : Si téléchargé en tant que `nagios`, le fichier peut avoir des
> permissions insuffisantes pour extraire. Utiliser `sudo wget` depuis `primaryos`.

---

## 3.2 Extraire l'archive

```bash
cd /home/nagios/downloads
sudo tar -zxvf nagios-plugins-2.5.tar.gz
cd nagios-plugins-2.5
```

---

## 3.3 Compiler les plugins

```bash
# ./configure nécessite sudo car exécuté depuis primaryos
sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagcmd

sudo make

sudo make install
```

---

## 3.4 Vérifier l'installation des plugins

```bash
ls -lrth /usr/local/nagios/libexec/
```

Vous devriez voir une liste de plugins comme :

```
check_cluster   check_disk      check_dummy     check_http
check_load      check_ping      check_procs     check_ssh
check_swap      check_tcp       check_users     check_nrpe
...
```

---

## 3.5 Corriger les alertes de l'interface web

Après installation des plugins, redémarrer Nagios :

```bash
sudo systemctl restart nagios
```

Les alertes rouges "No such file or directory" disparaîtront progressivement.

---

## ✅ Vérification finale Partie 3

```bash
# Tester un plugin manuellement
/usr/local/nagios/libexec/check_ping -H localhost -w 100.0,20% -c 500.0,60%
# PING OK - Packet loss = 0%, RTA = X.XX ms ✅

/usr/local/nagios/libexec/check_http -H localhost
# HTTP OK: HTTP/1.1 200 OK ✅
```

---

➡️ [Partie 4 — Configuration et interface web](04-configuration-interface.md)
