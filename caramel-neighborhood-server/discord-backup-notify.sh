#!/bin/bash

WEBHOOK_URL="${DISCORD_WEBHOOK_URL}"

if [ -z "$WEBHOOK_URL" ]; then
    echo "Error: DISCORD_WEBHOOK_URL is not set in .env file."
    exit 1
fi

echo "Preparing to send backup status notification to Discord..."

SERVER_NAME="${DISCORD_BACKUP_NOTIFY_SERVER_NAME:-My Minecraft Server}"

BACKUP_STATUS="$1"
BACKUP_LOG="$2"

if [ "$BACKUP_STATUS" -eq 0 ]; then
    EMOJI="🟢"
    STATUS_TEXT="Backup for $SERVER_NAME completed! ✅"
    COLOR=3066993
    MENTION="" # No ping on success
else
    EMOJI="🔴"
    STATUS_TEXT="Backup for $SERVER_NAME failed! ❌"
    COLOR=15158332
    MENTION="<@>396088921307611148" # Ping on failure
fi

if [ -f "$BACKUP_LOG" ]; then
    SHORT_LOG=$(head -n 50 "$BACKUP_LOG")
    LOG_PATH="$BACKUP_LOG"
else
    SHORT_LOG=""
    LOG_PATH=""
fi

escape_json() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g'
}

ESCAPED_LOG=$(escape_json "$SHORT_LOG")
ESCAPED_PATH=$(escape_json "$LOG_PATH")

FIELDS=""

if [ -n "$ESCAPED_LOG" ]; then
    FIELDS='{
      "name": "Backup Log (Truncated)",
      "value": "```\n'"$ESCAPED_LOG"'\n```"
    }'
fi

if [ -n "$ESCAPED_PATH" ]; then
    [ -n "$FIELDS" ] && FIELDS="$FIELDS,"  # Add comma only if previous field exists
    FIELDS="$FIELDS
    {
      \"name\": \"Backup Log Path\",
      \"value\": \"\`$ESCAPED_PATH\`\"
    }"
fi

# Build final JSON payload safely
PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "$EMOJI Minecraft Server Backup Status",
    "description": "$STATUS_TEXT",
    "color": $COLOR,
    "fields": [
      $FIELDS
    ],
    "footer": {
      "text": "setupmc.com backup status notifier"
    },
    "timestamp": "$(date -Iseconds)"
  }]
}
EOF
)

echo "Sending backup status notification to Discord..."

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$WEBHOOK_URL")

HTTP_BODY=$(echo "$RESPONSE" | sed '$d')
HTTP_STATUS=$(echo "$RESPONSE" | tail -n1 | cut -d: -f2)

if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
    echo "Backup status notification sent successfully to Discord."
else
    echo "An error occurred while sending the backup status notification to Discord:"
    echo "Status: $HTTP_STATUS"
    echo "Response body:"
    echo "$HTTP_BODY"
    exit 1
fi
