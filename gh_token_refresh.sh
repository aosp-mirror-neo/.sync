#!/bin/bash
# based on
# https://zenn.dev/coconala/articles/ee36ed7219a2ae

set -eo pipefail

PRIVATE_KEY="$PRIVATE_KEY"

now=$(date +%s)
iat=$((now - 60))
exp=$((now + 600))

base64url_encode() {
    openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'
}

create_header() {
    local header_json='{
        "typ": "JWT",
        "alg": "RS256"
    }'

    echo -n "$header_json" | base64url_encode
}

create_payload() {
    local payload_json="{
        \"iat\": ${iat},
        \"exp\": ${exp},
        \"iss\": \"${APP_ID}\"
    }"

    echo -n "$payload_json" | base64url_encode
}

sign_payload_with_key() {
    local header_payload="$1"
    echo -n "$header_payload" | openssl dgst -sha256 -sign <(printf "%b" "$PRIVATE_KEY") | base64url_encode
}

get_github_token() {
    local jwt="$1"
    response=$(curl --request POST \
        --url "https://api.github.com/app/installations/${INSTALLATION_ID}/access_tokens" \
        --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer ${jwt}" \
        --header "X-GitHub-Api-Version: 2022-11-28" \
        --silent)

    echo "${response}"
}

header=$(create_header)
payload=$(create_payload)
signature=$(sign_payload_with_key "${header}.${payload}")
jwt="${header}.${payload}.${signature}"

response=$(get_github_token "${jwt}")
token=$(echo "${response}" | jq -r '.token')

echo "${token}"
