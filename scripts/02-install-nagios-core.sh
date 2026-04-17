#!/bin/bash
# ============================================================
# Script 02 — Compilation et installation de Nagios Core 4.5.12
# ============================================================
# Usage : sudo bash scripts/02-install-nagios-core.sh
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

if [ "$EUID" -ne 0 ]; then
  error "Ce script doit être lancé avec sudo : sudo bash $0"
fi

NAGIOS_VERSION="4.5.12"
NAGIOS_URL="https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-${NAGIOS_VERSION}/nagios-${NAGIOS_VERSION}.tar.gz"
DOWNLOAD_DIR="/home/nagios/downloads"
BUILD_DIR="${DOWNLOAD_DIR}/nagios-${NAGIOS_VERSION}"

echo ""
echo "========================================="
echo "  Installation Nagios Core ${NAGIOS_VERSION}"
echo "========================================="
echo ""

# ─── Étape 1 : Télécharger les sources ─────────────────────
log "Téléchargement de Nagios Core ${NAGIOS_VERSION}..."
cd "$DOWNLOAD_DIR"

if [ ! -f "nagios-${NAGIOS_VERSION}.tar.gz" ]; then
  wget -q --show-progress "$NAGIOS_URL"
  chown nagios:nagios "nagios-${NAGIOS_VERSION}.tar.gz"
else
  warn "Archive déjà téléchargée, ignoré."
fi
log "Sources téléchargées."

# ─── Étape 2 : Extraire ────────────────────────────────────
log "Extraction des sources..."
if [ ! -d "$BUILD_DIR" ]; then
  sudo -u nagios tar -zxf "nagios-${NAGIOS_VERSION}.tar.gz"
else
  warn "Répertoire sources existe déjà, ignoré."
fi
log "Sources extraites dans ${BUILD_DIR}."

# ─── Étape 3 : Configure ───────────────────────────────────
log "Configuration de la compilation (./configure)..."
cd "$BUILD_DIR"
sudo -u nagios ./configure \
  --with-httpd-conf=/etc/apache2/sites-enabled \
  --with-command-group=nagcmd \
  2>&1 | tail -20
log "Configuration terminée."

# ─── Étape 4 : Compilation ─────────────────────────────────
log "Compilation des sources (make all)... Patientez ~2 minutes"
sudo -u nagios make all 2>&1 | tail -10
log "Compilation réussie."

# ─── Étape 5 : Installation ────────────────────────────────
log "Installation des binaires Nagios..."
make install
log "Binaires installés."

log "Installation groupes/users système..."
make install-groups-users
usermod -a -G nagios www-data
log "Groupes configurés."

log "Installation service systemd..."
make install-daemoninit
log "Service systemd installé."

log "Installation pipe de commandes..."
make install-commandmode
log "Pipe installé."

log "Installation fichiers de configuration..."
make install-config
log "Fichiers de config installés."

log "Installation configuration Apache..."
make install-webconf
log "Config Apache installée."

# ─── Étape 6 : Modules Apache ──────────────────────────────
log "Activation des modules Apache (rewrite, cgi)..."
a2enmod rewrite
a2enmod cgi
log "Modules Apache activés."

# ─── Étape 7 : Utilisateur web ─────────────────────────────
echo ""
warn "Création de l'utilisateur web Nagios (nagiosadmin)"
warn "Entrez un mot de passe sécurisé :"
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

# ─── Étape 8 : Permissions ─────────────────────────────────
log "Attribution des droits sur /usr/local/nagios..."
chown -R nagios:nagcmd /usr/local/nagios
log "Permissions configurées."

# ─── Étape 9 : Démarrage services ──────────────────────────
log "Redémarrage d'Apache2..."
systemctl restart apache2

log "Démarrage et activation de Nagios..."
systemctl enable nagios
systemctl start nagios

# ─── Vérifications ─────────────────────────────────────────
sleep 2
echo ""
echo "========================================="
echo "         Vérifications finales"
echo "========================================="

if systemctl is-active --quiet nagios; then
  log "Nagios : active (running) ✅"
else
  error "Nagios n'a pas démarré. Vérifiez : sudo systemctl status nagios"
fi

if systemctl is-active --quiet apache2; then
  log "Apache2 : active (running) ✅"
else
  error "Apache2 n'a pas démarré. Vérifiez : sudo systemctl status apache2"
fi

log "Test de la configuration Nagios..."
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg 2>&1 | grep -E "Total|Things"

IP=$(hostname -I | awk '{print $1}')
echo ""
log "✅ Nagios Core ${NAGIOS_VERSION} installé avec succès !"
echo ""
echo "Accéder à l'interface web :"
echo "  http://${IP}/nagios"
echo "  Login : nagiosadmin"
echo ""
echo "Prochaine étape :"
echo "  sudo bash scripts/03-install-plugins.sh"
echo ""
