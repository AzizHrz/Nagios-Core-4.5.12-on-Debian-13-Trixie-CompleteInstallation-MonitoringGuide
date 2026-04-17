#!/bin/bash
# ============================================================
# Script 01 — Préparation du serveur Debian 13.4 pour Nagios
# ============================================================
# Usage : sudo bash scripts/01-prepare-server.sh
# ============================================================

set -e  # Arrêter en cas d'erreur

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# Vérifier que le script tourne en root/sudo
if [ "$EUID" -ne 0 ]; then
  error "Ce script doit être lancé avec sudo : sudo bash $0"
fi

echo ""
echo "========================================="
echo "  Préparation Serveur Debian 13 → Nagios"
echo "========================================="
echo ""

# ─── Étape 1 : Mise à jour ─────────────────────────────────
log "Mise à jour du système..."
apt-get update -qq && apt-get upgrade -y -qq
log "Système à jour."

# ─── Étape 2 : Paquets de base ─────────────────────────────
log "Installation Apache2, PHP et dépendances de base..."
apt-get install -y -qq \
  apache2 \
  php \
  php-gd \
  php-curl \
  apt-transport-https \
  lsb-release \
  ca-certificates \
  curl
log "Apache2 et PHP installés."

# ─── Étape 3 : Dépôt Sury pour php8.4-imap ─────────────────
log "Ajout du dépôt Sury pour php8.4-imap..."
if [ ! -f /usr/share/keyrings/deb.sury.org-php.gpg ]; then
  curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg \
    https://packages.sury.org/php/apt.gpg
fi

CODENAME=$(lsb_release -sc)
echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] \
https://packages.sury.org/php/ ${CODENAME} main" \
  > /etc/apt/sources.list.d/php.list

apt-get update -qq
apt-get install -y -qq php8.4-imap
log "php8.4-imap installé depuis Sury."

# ─── Étape 4 : Bibliothèques Perl ──────────────────────────
log "Installation des bibliothèques Perl..."
apt-get install -y -qq \
  libxml-libxml-perl \
  libnet-snmp-perl \
  libperl-dev \
  libnumber-format-perl \
  libconfig-inifiles-perl \
  libdatetime-perl \
  libnet-dns-perl
log "Bibliothèques Perl installées."

# ─── Étape 5 : Bibliothèques compilation ───────────────────
log "Installation des outils de compilation et bibliothèques..."
apt-get install -y -qq \
  libpng-dev \
  libjpeg-dev \
  libgd-dev \
  libssl-dev \
  libkrb5-dev \
  gcc \
  make \
  autoconf \
  libc6 \
  unzip \
  build-essential \
  bc \
  gawk \
  dc \
  libapache2-mod-php \
  snmp \
  libnet-snmp-perl \
  gettext
log "Outils de compilation installés."

# ─── Étape 6 : Utilisateur et groupes Nagios ───────────────
log "Création de l'utilisateur nagios..."
if id "nagios" &>/dev/null; then
  warn "Utilisateur nagios existe déjà, ignoré."
else
  useradd -m nagios
  echo "nagios:nagios" | chpasswd
  warn "Mot de passe temporaire 'nagios' défini. Changez-le avec : sudo passwd nagios"
fi

log "Création du groupe nagcmd..."
if getent group nagcmd &>/dev/null; then
  warn "Groupe nagcmd existe déjà, ignoré."
else
  groupadd nagcmd
fi

log "Ajout des utilisateurs aux groupes..."
usermod -a -G nagcmd nagios
usermod -a -G nagcmd www-data
log "Groupes configurés."

# ─── Étape 7 : Répertoire de téléchargement ────────────────
log "Création du répertoire /home/nagios/downloads..."
mkdir -p /home/nagios/downloads
chown -R nagios:nagios /home/nagios/
chmod 755 /home/nagios/
log "Répertoire créé avec les bonnes permissions."

# ─── Démarrer Apache ───────────────────────────────────────
log "Démarrage d'Apache2..."
systemctl start apache2
systemctl enable apache2
log "Apache2 démarré et activé."

# ─── Vérifications finales ─────────────────────────────────
echo ""
echo "========================================="
echo "         Vérifications finales"
echo "========================================="
apache2 -v | head -1
php -v | head -1
gcc --version | head -1
make --version | head -1
id nagios
groups nagios

echo ""
log "✅ Serveur prêt pour l'installation de Nagios Core !"
echo ""
echo "Prochaine étape :"
echo "  sudo bash scripts/02-install-nagios-core.sh"
echo ""
