#!/usr/bin/env bash
# Nettoyage complet des zones et enregistrements DNS
# Usage: ./scripts/cleanup_zones_and_records.sh [--dry-run]
# IMPORTANT: ce script supprime définitivement des données. Tester en staging avant production.

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_NAME="${DB_NAME:-dns3_db}"
# DB_PASSWORD can be provided via env var or prompt
DB_PASSWORD="${DB_PASSWORD:-}"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
fi

if [[ -z "$DB_PASSWORD" ]]; then
    read -s -p "Mot de passe MySQL pour ${DB_USER}@${DB_HOST}: " DB_PASSWORD
    echo
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="backup_${DB_NAME}_${TIMESTAMP}.sql"

echo "==> MODE: $( [[ $DRY_RUN -eq 1 ]] && echo "DRY-RUN (aucune suppression effectuée)" || echo "LIVE" )"
echo "==> Sauvegarde de la base dans : $BACKUP_FILE"
echo "==> Hôte: $DB_HOST  Port: $DB_PORT  DB: $DB_NAME  User: $DB_USER"

if [[ $DRY_RUN -eq 0 ]]; then
    mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" --single-transaction --quick --routines --triggers "$DB_NAME" > "$BACKUP_FILE"
    echo "Sauvegarde terminée."
else
    echo "(dry-run) skip backup"
fi

cat <<'SQL' > /tmp/cleanup_zones_sql.sql
-- Supprime (ou met à jour) toutes les lignes liées aux zones et enregistrements DNS
-- Ajuste ces commandes si tu veux plutôt soft-delete (UPDATE ... SET status='deleted')

SET FOREIGN_KEY_CHECKS=0;

DELETE FROM dns_record_history;
DELETE FROM dns_records;

DELETE FROM zone_file_history;
DELETE FROM zone_file_includes;
DELETE FROM applications;
DELETE FROM zone_files;

SET FOREIGN_KEY_CHECKS=1;
SQL

echo
echo "=== SQL qui sera exécuté ==="
cat /tmp/cleanup_zones_sql.sql
echo "==========================="
echo

if [[ $DRY_RUN -eq 1 ]]; then
    echo "(dry-run) : pas d'exécution"
    exit 0
fi

read -p "CONFIRMEZ-VOUS la suppression définitive de toutes les zones et records dans la base ${DB_NAME}? (oui/NO): " CONF
if [[ "$CONF" != "oui" ]]; then
    echo "Annulé par l'utilisateur."
    exit 1
fi

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < /tmp/cleanup_zones_sql.sql

echo "Suppression effectuée. Le dump est disponible : $BACKUP_FILE"
echo "Si nécessaire, restaurez avec : mysql -u ${DB_USER} -p ${DB_NAME} < $BACKUP_FILE"
