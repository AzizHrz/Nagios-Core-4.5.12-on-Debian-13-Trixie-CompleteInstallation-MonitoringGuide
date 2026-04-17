#!/bin/bash
# ============================================================
# Script 04 — Configuration finale et vérifications
# ============================================================
# Usage : sudo bash scripts/04-configure-nagios.sh
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être lancé avec sudo"
  exit 1
fi

echo ""
echo "========================================="
echo "    Configuration finale Nagios"
echo "========================================="
echo ""

# ─── Vérification config Nagios ────────────────────────────
log "Vérification de la configuration Nagios..."
CONFIG_CHECK=$(/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg 2>&1)
WARNINGS=$(echo "$CONFIG_CHECK" | grep "Total Warnings" | awk '{print $3}')
ERRORS=$(echo "$CONFIG_CHECK" | grep "Total Errors" | awk '{print $3}')

echo "$CONFIG_CHECK" | grep -E "Total|Things"

if [ "$ERRORS" = "0" ]; then
  log "Configuration valide : 0 erreurs ✅"
else
  warn "Configuration a ${ERRORS} erreur(s). Vérifiez manuellement."
fi

# ─── Ajouter alias utile ────────────────────────────────────
log "Ajout de l'alias testNagios dans /etc/bash.bashrc..."
ALIAS_LINE="alias testNagios='sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg'"

if ! grep -q "testNagios" /etc/bash.bashrc; then
  echo "$ALIAS_LINE" >> /etc/bash.bashrc
  log "Alias ajouté. Relancez votre terminal ou faites : source /etc/bash.bashrc"
else
  warn "Alias testNagios existe déjà."
fi

# ─── Statut des services ────────────────────────────────────
echo ""
echo "========================================="
echo "         Statut des services"
echo "========================================="

if systemctl is-active --quiet nagios; then
  log "Nagios    : ✅ active (running)"
else
  warn "Nagios    : ❌ inactif"
fi

if systemctl is-active --quiet apache2; then
  log "Apache2   : ✅ active (running)"
else
  warn "Apache2   : ❌ inactif"
fi

# ─── Informations de connexion ──────────────────────────────
IP=$(hostname -I | awk '{print $1}')
NAGIOS_VERSION=$(/usr/local/nagios/bin/nagios --version 2>&1 | grep "Nagios Core" | awk '{print $3}')

echo ""
echo "========================================="
echo "       Informations de connexion"
echo "========================================="
info "Version Nagios : ${NAGIOS_VERSION}"
info "Interface web  : http://${IP}/nagios"
info "Login          : nagiosadmin"
info "Logs           : /usr/local/nagios/var/nagios.log"
info "Config         : /usr/local/nagios/etc/nagios.cfg"
info "Plugins        : /usr/local/nagios/libexec/"

echo ""
echo "========================================="
echo "         Commandes utiles"
echo "========================================="
echo "  Tester config  : testNagios  (ou sudo /usr/local/nagios/bin/nagios -v ...)"
echo "  Recharger      : sudo systemctl reload nagios"
echo "  Voir logs      : sudo tail -f /usr/local/nagios/var/nagios.log"
echo "  Statut Nagios  : sudo systemctl status nagios"
echo ""
log "✅ Installation et configuration Nagios terminées !"
echo ""
