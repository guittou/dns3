#!/usr/bin/env bash
# Nettoyage complet des zones et enregistrements DNS
# Usage: ./scripts/cleanup_zones_and_records.sh [--dry-run] [--soft-delete]
# IMPORTANT: ce script supprime définitivement des données. Tester en staging avant production.

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_NAME="${DB_NAME:-dns3_db}"
DB_PASSWORD="${DB_PASSWORD:-}"

DRY_RUN=0
SOFT_DELETE=0

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=1
            ;;
        --soft-delete)
            SOFT_DELETE=1
            ;;
    esac
done

if [[ -z "$DB_PASSWORD" ]]; then
    read -s -p "Mot de passe MySQL pour ${DB_USER}@${DB_HOST}: " DB_PASSWORD
    echo
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="backup_${DB_NAME}_${TIMESTAMP}.sql"
SQL_FILE="/tmp/cleanup_zones_sql_${TIMESTAMP}.sql"

echo "============================================"
echo "  Nettoyage des zones et enregistrements DNS"
echo "============================================"
echo "MODE: $( [[ $DRY_RUN -eq 1 ]] && echo "DRY-RUN (aucune suppression effectuée)" || echo "LIVE" )"
echo "SOFT-DELETE: $( [[ $SOFT_DELETE -eq 1 ]] && echo "YES (UPDATE status='deleted')" || echo "NO (DELETE)" )"
echo "Hôte: $DB_HOST  Port: $DB_PORT  DB: $DB_NAME  User: $DB_USER"
echo "Fichier SQL: $SQL_FILE"
echo

if [[ $DRY_RUN -eq 0 ]]; then
    echo "==> Sauvegarde de la base dans : $BACKUP_FILE"
    mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" --single-transaction --quick --routines --triggers "$DB_NAME" > "$BACKUP_FILE"
    echo "Sauvegarde terminée."
    echo
else
    echo "(dry-run) skip backup"
    echo
fi

# Tables candidates à nettoyer
CANDIDATE_TABLES=(
    "dns_record_history"
    "dns_records"
    "zone_file_history"
    "zone_file_includes"
    "zone_file_includes_new"
    "zone_file_validation"
    "applications"
    "zone_files"
)

echo "==> Détection des tables existantes via information_schema..."
EXISTING_TABLES=()
MISSING_TABLES=()

for table in "${CANDIDATE_TABLES[@]}"; do
    CHECK_QUERY="SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME' AND table_name='$table'"
    COUNT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -N -s -e "$CHECK_QUERY")
    
    if [[ "$COUNT" -gt 0 ]]; then
        EXISTING_TABLES+=("$table")
        echo "  ✓ Table trouvée: $table"
    else
        MISSING_TABLES+=("$table")
        echo "  ✗ Table absente: $table (skip)"
    fi
done

echo
echo "==> Tables détectées: ${#EXISTING_TABLES[@]}"
echo "==> Tables absentes: ${#MISSING_TABLES[@]}"
echo

# Génération du SQL dynamique
echo "==> Génération du SQL de nettoyage..."

cat > "$SQL_FILE" <<'HEADER'
-- Nettoyage automatique des zones et enregistrements DNS
-- Généré dynamiquement en fonction des tables existantes

SET FOREIGN_KEY_CHECKS=0;

HEADER

for table in "${EXISTING_TABLES[@]}"; do
    # Vérifier si la table a une colonne 'status' pour --soft-delete
    if [[ $SOFT_DELETE -eq 1 ]]; then
        CHECK_STATUS_QUERY="SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='$DB_NAME' AND table_name='$table' AND column_name='status'"
        HAS_STATUS=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -N -s -e "$CHECK_STATUS_QUERY")
        
        if [[ "$HAS_STATUS" -gt 0 ]]; then
            echo "-- Soft-delete for $table (has status column)" >> "$SQL_FILE"
            echo "UPDATE \`$table\` SET status='deleted' WHERE COALESCE(status,'') != 'deleted';" >> "$SQL_FILE"
            echo "  → Soft-delete: UPDATE $table SET status='deleted'"
        else
            echo "-- Delete from $table (no status column)" >> "$SQL_FILE"
            echo "DELETE FROM \`$table\`;" >> "$SQL_FILE"
            echo "  → Delete: DELETE FROM $table"
        fi
    else
        echo "-- Delete from $table" >> "$SQL_FILE"
        echo "DELETE FROM \`$table\`;" >> "$SQL_FILE"
        echo "  → Delete: DELETE FROM $table"
    fi
    echo >> "$SQL_FILE"
done

cat >> "$SQL_FILE" <<'FOOTER'
SET FOREIGN_KEY_CHECKS=1;
FOOTER

echo
echo "=== SQL généré ==="
cat "$SQL_FILE"
echo "=================="
echo

if [[ $DRY_RUN -eq 1 ]]; then
    echo "(dry-run) : pas d'exécution réelle du SQL"
    echo "Le fichier SQL est disponible pour inspection: $SQL_FILE"
    exit 0
fi

echo "ATTENTION: Cette opération va $( [[ $SOFT_DELETE -eq 1 ]] && echo "marquer comme supprimées (soft-delete)" || echo "supprimer définitivement" ) toutes les données"
echo "des tables suivantes: ${EXISTING_TABLES[*]}"
echo
read -p "CONFIRMEZ-VOUS cette opération dans la base ${DB_NAME}? (oui/NO): " CONF
if [[ "$CONF" != "oui" ]]; then
    echo "Annulé par l'utilisateur."
    exit 1
fi

echo
echo "==> Exécution du SQL..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$SQL_FILE"

echo
echo "============================================"
echo "  Nettoyage terminé avec succès"
echo "============================================"
echo "Backup disponible: $BACKUP_FILE"
echo "SQL exécuté: $SQL_FILE"
echo "Pour restaurer: mysql -u ${DB_USER} -p ${DB_NAME} < $BACKUP_FILE"
echo
