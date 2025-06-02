# Injector Tools

This repository contains two Bash scripts for automated vulnerability injection testing:
- **sqlinjector** — Script to inject SQLi payloads.
- **xssinjector** — Script to inject XSS payloads.

## Features

- Automated payload injection for SQL Injection and Cross-Site Scripting vulnerabilities.
- Simple command-line interface.
- Logs suspicious responses for analysis.

## Requirements

- Bash shell
- `jq` (for JSON parsing in logs and outputs)
- `curl` (for HTTP requests)

To install `jq` on Kali Linux:

```bash
sudo apt update && sudo apt install jq -y
