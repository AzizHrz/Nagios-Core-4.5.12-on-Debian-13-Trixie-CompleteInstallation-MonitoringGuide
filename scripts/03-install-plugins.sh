#!/bin/bash
# ============================================================
# Script 03 — Installation des plugins Nagios 2.5
# ============================================================
# Usage : sudo bash scripts/03-install-plugins.sh [options]
#
# Options :
#   --with-mysql    Installe les prérequis pour check_mysql
#   --with-pgsql    Installe les prérequis pour check_pgsql
#   --with-ldap     Installe les prérequis pour check_ldap
#   --with-smb      Installe les prérequis pour check_disk_smb
#   --with-snmp     Installe les prérequis pour check_snmp
#   --with-all      Installe tous les prérequis optionnels
#
# Exemple :
#   sudo bash scripts/03-install-plugins.sh --with-mysql --with-snmp
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
info()  { echo -e "${BLUE}[i]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

if [ "$EUID" -ne 0 ]; then
  error "Ce script doit être lancé avec sudo : sudo bash $0"
fi

# ─── Parse options ─────────────────────────────────────────
WITH_MYSQL=false
WITH_PGSQL=false
WITH_LDAP=false
WITH_SMB=false
WITH_SNMP=false

for arg in "$@"; do
  case $arg in
    --with-mysql) WITH_MYSQL=true ;;
    --with-pgsql) WITH_PGSQL=true ;;
    --with-ldap)  WITH_LDAP=true  ;;
    --with-smb)   WITH_SMB=true   ;;
    --with-snmp)  WITH_SNMP=true  ;;
    --with-all)
      WITH_MYSQL=true
      WITH_PGSQL=true
      WITH_LDAP=true
      WITH_SMB=true
      WITH_SNMP=true
      ;;
  esac
done

PLUGINS_VERSION="2.5"
PLUGINS_URL="https://nagios-plugins.org/download/nagios-plugins-${PLUGINS_VERSION}.tar.gz"
DOWNLOAD_DIR="/home/nagios/downloads"
BUILD_DIR="${DOWNLOAD_DIR}/nagios-plugins-${PLUGINS_VERSION}"

echo ""
echo "========================================="
echo "  Installation Plugins Nagios ${PLUGINS_VERSION}"
echo "========================================="
echo ""

# ─── Prérequis optionnels ──────────────────────────────────
if [ "$WITH_MYSQL" = true ]; then
  log "Installation prérequis MySQL (check_mysql)..."
  apt-get install -y -qq libmysqlclient-dev
  log "libmysqlclient-dev installé."
fi

if [ "$WITH_PGSQL" = true ]; then
  log "Installation prérequis PostgreSQL (check_pgsql)..."
  apt-get install -y -qq libpq-dev
  log "libpq-dev installé."
fi

if [ "$WITH_LDAP" = true ]; then
  log "Installation prérequis LDAP (check_ldap)..."
  apt-get install -y -qq libldap2-dev
  log "libldap2-dev installé."
fi

if [ "$WITH_SMB" = true ]; then
  log "Installation prérequis Samba (check_disk_smb)..."
  apt-get install -y -qq smbclient
  log "smbclient installé."
fi

if [ "$WITH_SNMP" = true ]; then
  log "Installation prérequis SNMP (check_snmp)..."
  apt-get install -y -qq snmp snmpd libnet-snmp-perl
  log "SNMP installé."
fi

# ─── Télécharger ───────────────────────────────────────────
log "Téléchargement des plugins Nagios ${PLUGINS_VERSION}..."
cd "$DOWNLOAD_DIR"

if [ ! -f "nagios-plugins-${PLUGINS_VERSION}.tar.gz" ]; then
  wget -q --show-progress "$PLUGINS_URL"
  chown nagios:nagios "nagios-plugins-${PLUGINS_VERSION}.tar.gz"
else
  warn "Archive plugins déjà téléchargée, ignoré."
fi

# ─── Extraire ──────────────────────────────────────────────
log "Extraction des sources plugins..."
if [ -d "$BUILD_DIR" ]; then
  warn "Répertoire existe, suppression pour recompilation propre..."
  rm -rf "$BUILD_DIR"
fi
tar -zxf "nagios-plugins-${PLUGINS_VERSION}.tar.gz"
chown -R nagios:nagios "nagios-plugins-${PLUGINS_VERSION}"

# ─── Configure ─────────────────────────────────────────────
log "Configuration des plugins..."
cd "$BUILD_DIR"

CONFIGURE_OPTS="--with-nagios-user=nagios --with-nagios-group=nagcmd"
[ "$WITH_MYSQL" = true ] && CONFIGURE_OPTS="$CONFIGURE_OPTS --with-mysql"
[ "$WITH_PGSQL" = true ] && CONFIGURE_OPTS="$CONFIGURE_OPTS --with-pgsql"

./configure $CONFIGURE_OPTS 2>&1 | tail -5
log "Configuration terminée."

# ─── Compiler et installer ─────────────────────────────────
log "Compilation des plugins... Patientez ~3 minutes"
make 2>&1 | tail -3

log "Installation des plugins..."
make install
log "Plugins installés dans /usr/local/nagios/libexec/"

# ─── Redémarrer Nagios ─────────────────────────────────────
log "Redémarrage de Nagios..."
systemctl restart nagios
sleep 2

# ─── Vérifications ─────────────────────────────────────────
echo ""
echo "========================================="
echo "         Plugins installés"
echo "========================================="

PLUGIN_COUNT=$(ls /usr/local/nagios/libexec/ | wc -l)
log "Nombre de plugins : ${PLUGIN_COUNT}"

echo ""
info "Test des plugins standards :"

test_plugin() {
  local name=$1
  local cmd=$2
  if eval "$cmd" &>/dev/null; then
    echo -e "  ${GREEN}✅${NC} $name"
  else
    echo -e "  ${YELLOW}⚠️ ${NC} $name (vérifiez manuellement)"
  fi
}

test_plugin "check_ping"  "/usr/local/nagios/libexec/check_ping -H 127.0.0.1 -w 100.0,20% -c 500.0,60%"
test_plugin "check_http"  "/usr/local/nagios/libexec/check_http -H localhost"
test_plugin "check_disk"  "/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /"
test_plugin "check_load"  "/usr/local/nagios/libexec/check_load -w 5.0,4.0,3.0 -c 10.0,8.0,6.0"
test_plugin "check_users" "/usr/local/nagios/libexec/check_users -w 5 -c 10"
test_plugin "check_swap"  "/usr/local/nagios/libexec/check_swap -w 20% -c 10%"

if systemctl is-active --quiet nagios; then
  echo ""
  log "Nagios : active (running) ✅"
fi

echo ""
log "✅ Plugins Nagios ${PLUGINS_VERSION} installés avec succès !"
echo ""
info "Pour installer des plugins optionnels plus tard :"
echo "  sudo bash scripts/03-install-plugins.sh --with-mysql"
echo "  sudo bash scripts/03-install-plugins.sh --with-all"
echo ""
