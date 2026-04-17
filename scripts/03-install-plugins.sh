#!/bin/bash
# ============================================================
# Script 03 — Installation des plugins Nagios 2.5
# ============================================================
# Usage : sudo bash scripts/03-install-plugins.sh
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

PLUGINS_VERSION="2.5"
PLUGINS_URL="https://nagios-plugins.org/download/nagios-plugins-${PLUGINS_VERSION}.tar.gz"
DOWNLOAD_DIR="/home/nagios/downloads"
BUILD_DIR="${DOWNLOAD_DIR}/nagios-plugins-${PLUGINS_VERSION}"

echo ""
echo "========================================="
echo "  Installation Plugins Nagios ${PLUGINS_VERSION}"
echo "========================================="
echo ""

# ─── Étape 1 : Télécharger ─────────────────────────────────
log "Téléchargement des plugins Nagios ${PLUGINS_VERSION}..."
cd "$DOWNLOAD_DIR"

if [ ! -f "nagios-plugins-${PLUGINS_VERSION}.tar.gz" ]; then
  wget -q --show-progress "$PLUGINS_URL"
  chown nagios:nagios "nagios-plugins-${PLUGINS_VERSION}.tar.gz"
else
  warn "Archive plugins déjà téléchargée, ignoré."
fi
log "Plugins téléchargés."

# ─── Étape 2 : Extraire ────────────────────────────────────
log "Extraction des sources plugins..."
if [ ! -d "$BUILD_DIR" ]; then
  tar -zxf "nagios-plugins-${PLUGINS_VERSION}.tar.gz"
  chown -R nagios:nagios "nagios-plugins-${PLUGINS_VERSION}"
else
  warn "Répertoire plugins existe déjà, ignoré."
fi
log "Sources plugins extraites."

# ─── Étape 3 : Configure ───────────────────────────────────
log "Configuration des plugins..."
cd "$BUILD_DIR"
./configure \
  --with-nagios-user=nagios \
  --with-nagios-group=nagcmd \
  2>&1 | tail -5
log "Configuration plugins terminée."

# ─── Étape 4 : Compiler et installer ───────────────────────
log "Compilation des plugins... Patientez ~3 minutes"
make 2>&1 | tail -5
log "Compilation plugins terminée."

log "Installation des plugins..."
make install
log "Plugins installés dans /usr/local/nagios/libexec/"

# ─── Étape 5 : Redémarrer Nagios ───────────────────────────
log "Redémarrage de Nagios pour prendre en compte les plugins..."
systemctl restart nagios
sleep 2

# ─── Vérifications ─────────────────────────────────────────
echo ""
echo "========================================="
echo "         Vérifications"
echo "========================================="

PLUGIN_COUNT=$(ls /usr/local/nagios/libexec/ | wc -l)
log "Nombre de plugins installés : ${PLUGIN_COUNT}"

log "Test check_ping sur localhost..."
if /usr/local/nagios/libexec/check_ping -H 127.0.0.1 -w 100.0,20% -c 500.0,60% &>/dev/null; then
  log "check_ping : OK ✅"
else
  warn "check_ping : problème détecté"
fi

log "Test check_http sur localhost..."
if /usr/local/nagios/libexec/check_http -H localhost &>/dev/null; then
  log "check_http : OK ✅"
else
  warn "check_http : problème détecté (Apache peut être en cours de démarrage)"
fi

if systemctl is-active --quiet nagios; then
  log "Nagios : active (running) ✅"
fi

echo ""
log "✅ Plugins Nagios ${PLUGINS_VERSION} installés avec succès !"
echo ""
echo "Les erreurs 'No such file or directory' dans l'interface"
echo "web devraient disparaître dans les prochaines minutes."
echo ""
echo "Prochaine étape :"
echo "  sudo bash scripts/04-configure-nagios.sh"
echo ""
