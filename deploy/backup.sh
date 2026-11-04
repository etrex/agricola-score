#!/bin/sh
# 每日備份 SQLite（用 .backup 取得一致的快照，WAL 模式下也安全），保留 14 份。
# 備份含使用者資料，只有 root 可讀。
set -eu
umask 077
DB=/var/lib/agricola-score/agricola.db
OUT=/var/backups/agricola-score
mkdir -p "$OUT"
chmod 700 "$OUT"
sqlite3 "$DB" ".backup '$OUT/agricola-$(date +%Y%m%d).db'"
find "$OUT" -name 'agricola-*.db' -mtime +14 -delete
