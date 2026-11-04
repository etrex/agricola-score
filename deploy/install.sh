#!/bin/sh
# 在 VM 上執行：sudo sh install.sh
# 事先需要放在家目錄：agricola-score.bin、site.tgz、line-secrets.env、dynamodb-export.json（可選）
# 以及本目錄的 agricola-score.service、Caddyfile、backup.sh
set -eux
H="${SUDO_HOME:-$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)}"

id agricola >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin agricola

install -m 755 "$H/agricola-score.bin" /usr/local/bin/agricola-score
install -d -m 750 -o root -g agricola /etc/agricola-score
install -m 600 -o root -g root "$H/line-secrets.env" /etc/agricola-score/env

install -m 644 "$H/agricola-score.service" /etc/systemd/system/agricola-score.service
install -m 755 "$H/backup.sh" /usr/local/bin/agricola-backup

# 靜態頁
install -d -m 755 /var/www/agricola
tar xzf "$H/site.tgz" -C /var/www/agricola

# 資料：第一次安裝才匯入（資料庫已存在就不要覆蓋）
install -d -m 750 -o agricola -g agricola /var/lib/agricola-score
if [ -f "$H/dynamodb-export.json" ] && [ ! -f /var/lib/agricola-score/agricola.db ]; then
  # 匯出檔只有登入帳號讀得到；暫時複製一份給 agricola 使用者，匯入後立刻刪除
  install -m 600 -o agricola -g agricola "$H/dynamodb-export.json" /var/lib/agricola-score/import.json
  runuser -u agricola -- env DB_PATH=/var/lib/agricola-score/agricola.db /usr/local/bin/agricola-score import-dynamodb /var/lib/agricola-score/import.json
  rm -f /var/lib/agricola-score/import.json
fi

# 每日備份
cat > /etc/systemd/system/agricola-backup.service <<'UNIT'
[Unit]
Description=Backup agricola-score SQLite
[Service]
Type=oneshot
ExecStart=/usr/local/bin/agricola-backup
UNIT
cat > /etc/systemd/system/agricola-backup.timer <<'UNIT'
[Unit]
Description=Daily backup of agricola-score
[Timer]
OnCalendar=daily
Persistent=true
[Install]
WantedBy=timers.target
UNIT

install -m 644 "$H/Caddyfile" /etc/caddy/Caddyfile

systemctl daemon-reload
systemctl enable --now agricola-score.service agricola-backup.timer
systemctl restart caddy
systemctl is-active agricola-score caddy
