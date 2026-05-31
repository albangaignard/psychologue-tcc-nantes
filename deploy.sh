#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Build Jekyll & déploiement FTP
# Usage :
#   ./deploy.sh                        # demande le mot de passe interactivement
#   FTP_PASSWORD=secret ./deploy.sh    # mot de passe via variable d'environnement
# =============================================================================

set -euo pipefail

# ── Configuration FTP ─────────────────────────────────────────────────────────
FTP_HOST="ftp.cluster110.hosting.ovh.net"
FTP_USER="psycholoo"
FTP_REMOTE_DIR="/www"       # chemin distant
LOCAL_SITE_DIR="./_site"

# ── Couleurs ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Vérification des dépendances ──────────────────────────────────────────────
command -v bundle >/dev/null 2>&1 || error "bundler introuvable — installez-le avec : gem install bundler"
command -v lftp   >/dev/null 2>&1 || error "lftp introuvable — installez-le avec : brew install lftp"

# ── Mot de passe ──────────────────────────────────────────────────────────────
if [[ -z "${FTP_PASSWORD:-}" ]]; then
  echo -n "Mot de passe FTP pour ${FTP_USER}@${FTP_HOST} : "
  read -rs FTP_PASSWORD
  echo
fi
[[ -z "$FTP_PASSWORD" ]] && error "Mot de passe vide."

# ── 1. Build Jekyll ───────────────────────────────────────────────────────────
info "Construction du site Jekyll…"
JEKYLL_ENV=production bundle exec jekyll build --destination "$LOCAL_SITE_DIR"
info "Build terminé → ${LOCAL_SITE_DIR}"

# ── 2. Déploiement FTP ────────────────────────────────────────────────────────
info "Déploiement vers ${FTP_HOST}…"

lftp -u "${FTP_USER},${FTP_PASSWORD}" "${FTP_HOST}" <<EOF
set ssl:verify-certificate no
set ftp:passive-mode true
mirror --reverse \
       --delete \
       --verbose \
       --exclude-glob .DS_Store \
       --exclude-glob .git/ \
       "${LOCAL_SITE_DIR}/" "${FTP_REMOTE_DIR}"
bye
EOF

info "✅  Déploiement terminé avec succès !"
