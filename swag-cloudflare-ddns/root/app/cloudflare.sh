#!/usr/bin/with-contenv bash
# shellcheck shell=bash

set -e

source "/config/ddns/cloudflare.ini"


log() {
    local message=$1
    printf "%s\n" "$( date -u "+%Y-%m-%d %H:%M:%S" ) - $message"
}


# Check if all variables are set
if [ -z "$cloudflare_api_zone_id" ] || [ -z "$cloudflare_api_zone_token" ] || [ -z "$record_domain" ] || [ -z "$record_type" ]; then
    log "Error: One or more required variables are not set in cloudflare.ini"
    exit 1
fi


# Check required programs before we continue.
for program in curl jq; do
    if ! hash "$program" 2>/dev/null
    then
        log "$program is not installed"
        exit 2
    fi
done

# Get the domain IP and record ID from the current record from the Cloudflare api.
response=$(curl -s "https://api.cloudflare.com/client/v4/zones/$cloudflare_api_zone_id/dns_records?type=$record_type&name=$record_domain" \
    -H "Authorization: Bearer $cloudflare_api_zone_token" \
    -H "Content-Type: application/json")
result=$(echo "$response" | jq -r '.success')

if [[ $result == "true" ]]; then
    domain_ip=$(echo "$response" | jq -r '.result[0].content')
    record_id=$(echo "$response" | jq -r '.result[0].id')
else
    error=$(echo "$response" | jq -r '.errors[0].message')
    log "Could not get domain IP address: $error"
    exit 2
fi

# Get the local IP from Cloudflare trace.
response=$(curl -s https://cloudflare.com/cdn-cgi/trace)
local_ip=$(echo "$response" | awk -F '=' '/ip/{print $2}')

# Compare domain IP with local IP.
if [[ "${domain_ip}" != "${local_ip}" ]] ; then
    log "IP address has changed to ${local_ip} (was $domain_ip). Updating DNS record."

    # Update content of the existing DNS record.
    response=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$cloudflare_api_zone_id/dns_records/$record_id" \
        -H "Authorization: Bearer $cloudflare_api_zone_token" \
        -H "Content-Type: application/json" \
        --data "{\"content\":\"$local_ip\"}")
    result=$(echo "$response" | jq -r '.success')

    if [[ $result == "true" ]]; then
        log "DNS record updated successfully"
    else
        error=$(echo "$response" | jq -r '.errors[0].message')
        log "Could not update DNS record: $error"
        exit 2
    fi
else
    log "Still happy at ${local_ip}"
fi
