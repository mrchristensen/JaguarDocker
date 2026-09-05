#!/bin/sh

set -eu

API_URL="https://api.dreamhost.com/"
IP_URL="https://api.ipify.org"
API_KEY="${DREAMHOST_API_KEY}"
RECORD="${DREAMHOST_RECORD}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*"
}

api_call() {
    command="$1"
    shift

    curl -fsS \
        --get \
        --data-urlencode "key=${API_KEY}" \
        --data-urlencode "cmd=${command}" \
        --data-urlencode "format=json" \
        --data-urlencode "unique_id=$(cat /proc/sys/kernel/random/uuid)" \
        "$@" \
        "$API_URL"
}

log "Checking public IP..."

CURRENT_IP="$(curl -fsS --max-time 10 "$IP_URL")"

if ! echo "$CURRENT_IP" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    log "ERROR: Invalid public IP returned: $CURRENT_IP"
    exit 1
fi

log "Current public IP: $CURRENT_IP"

log "Checking DreamHost DNS record..."

DNS_RESPONSE="$(api_call dns-list_records)"

OLD_IP="$(
    echo "$DNS_RESPONSE" |
        jq -r --arg record "$RECORD" '
            .data[]
            | select(.record == $record and .type == "A")
            | .value
        ' |
        head -n 1
)"

if [ -z "$OLD_IP" ] || [ "$OLD_IP" = "null" ]; then
    log "No existing A record found for $RECORD"
    OLD_IP=""
else
    log "DreamHost currently points $RECORD to $OLD_IP"
fi

if [ "$CURRENT_IP" = "$OLD_IP" ]; then
    log "IP has not changed. Nothing to do."
    exit 0
fi

log "IP changed: ${OLD_IP:-<none>} -> $CURRENT_IP"

if [ -n "$OLD_IP" ]; then
    log "Removing old A record..."

    REMOVE_RESPONSE="$(
        api_call dns-remove_record \
            --data-urlencode "record=${RECORD}" \
            --data-urlencode "type=A" \
            --data-urlencode "value=${OLD_IP}"
    )"

    echo "$REMOVE_RESPONSE" | jq .

    if ! echo "$REMOVE_RESPONSE" | jq -e '.result == "success"' >/dev/null; then
        log "ERROR: Failed to remove old DNS record."
        exit 1
    fi
fi

log "Adding new A record..."

ADD_RESPONSE="$(
    api_call dns-add_record \
        --data-urlencode "record=${RECORD}" \
        --data-urlencode "type=A" \
        --data-urlencode "value=${CURRENT_IP}"
)"

echo "$ADD_RESPONSE" | jq .

if ! echo "$ADD_RESPONSE" | jq -e '.result == "success"' >/dev/null; then
    log "ERROR: Failed to add new DNS record."
    exit 1
fi

log "Successfully updated $RECORD -> $CURRENT_IP"
