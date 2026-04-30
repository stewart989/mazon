send_backup_to_telegram() {
    if command -v yq >/dev/null 2>&1; then
        BACKUP_TELEGRAM_BOT_KEY=$(yq -r '.BACKUP_TELEGRAM_BOT_KEY // ""' "$ENV_FILE" 2>/dev/null || echo "")
        BACKUP_TELEGRAM_CHAT_ID=$(yq -r '.BACKUP_TELEGRAM_CHAT_ID // ""' "$ENV_FILE" 2>/dev/null || echo "")
        BACKUP_ENCRYPTION_KEY=$(yq -r '.BACKUP_ENCRYPTION_KEY // ""' "$ENV_FILE" 2>/dev/null || echo "")
    else
        BACKUP_TELEGRAM_BOT_KEY=$(grep '^BACKUP_TELEGRAM_BOT_KEY=' "$ENV_FILE" | cut -d= -f2- | tr -d '"'"'"' | xargs)
        BACKUP_TELEGRAM_CHAT_ID=$(grep '^BACKUP_TELEGRAM_CHAT_ID=' "$ENV_FILE" | cut -d= -f2- | tr -d '"'"'"' | xargs)
        BACKUP_ENCRYPTION_KEY=$(grep '^BACKUP_ENCRYPTION_KEY=' "$ENV_FILE" | cut -d= -f2- | tr -d '"'"'"' | xargs)
    fiif [ "$BACKUP_SERVICE_ENABLED" != "true" ]; then
    return
fi

local server_ip=$(curl -s ifconfig.me || echo "Unknown IP")
local latest_backup=$(ls -t "$APP_DIR/backup" 2>/dev/null | head -n 1)
local backup_path="$APP_DIR/backup/$latest_backup"

if [ ! -f "$backup_path" ]; then
    return
fi

local encrypted_backup="$backup_path.enc"
if command -v age >/dev/null 2>&1 && [ -n "$BACKUP_ENCRYPTION_KEY" ]; then
    echo "$BACKUP_ENCRYPTION_KEY" | age -e -o "$encrypted_backup" "$backup_path" 2>/dev/null || return 1
    backup_path="$encrypted_backup"
fi

local backup_size=$(du -m "$backup_path" | cut -f1)
local split_dir="/tmp/marzban_backup_split_$(date +%s)"
mkdir -p "$split_dir"

if [ "$backup_size" -gt 49 ]; then
    split -b 49M "$backup_path" "$split_dir/part_"
else
    cp "$backup_path" "$split_dir/part_00"
fi

for part in "$split_dir"/part_*; do
    curl -s -F "chat_id=$BACKUP_TELEGRAM_CHAT_ID" \
         -F "document=@$part" \
         -F "caption=Marzban Backup from $server_ip $(basename "$part")" \
         "https://api.telegram.org/bot$BACKUP_TELEGRAM_BOT_KEY/sendDocument" >/dev/null || true
done

rm -rf "$split_dir"
[ -f "$encrypted_backup" ] && rm -f "$encrypted_backup"}

