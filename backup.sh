#!/usr/bin/env bash
set -euo pipefail

: "${S3_BUCKET:?S3_BUCKET not set}"
: "${POSTGRES_URL:?POSTGRES_URL not set}"
: "${BACKUP_RETENTION_DAYS:=30}"

readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly TMP_DIR="$(mktemp -d)"
readonly BACKUP_NAME="backup_${TIMESTAMP}.sql.gz"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

dump_db() {
    pg_dump "$POSTGRES_URL" | gzip > "$TMP_DIR/$BACKUP_NAME"
}

upload() {
    aws s3 cp "$TMP_DIR/$BACKUP_NAME" "s3://$S3_BUCKET/db/$BACKUP_NAME" \
        --storage-class STANDARD_IA
}

prune_old() {
    local cutoff
    cutoff="$(date -d "${BACKUP_RETENTION_DAYS} days ago" +%Y-%m-%d)"
    aws s3 ls "s3://$S3_BUCKET/db/" \
        | awk -v cutoff="$cutoff" '$1 < cutoff {print $4}' \
        | while read -r key; do
            aws s3 rm "s3://$S3_BUCKET/db/$key"
        done
}

main() {
    dump_db
    upload
    prune_old
    echo "backup complete: $BACKUP_NAME"
}

main "$@"
