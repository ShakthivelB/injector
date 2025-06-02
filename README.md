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

 ```
Usage
Navigate to the respective folders and run the scripts:

 ```cd sqlinjector
./SQL.sh
 
cd ../xssinjector
./XSS.sh
   ```
 ``` Make sure the scripts are executable:
 
chmod +x SQL.sh XSS.sh
```
-u → URL input

-f → file input (list of URLs)

-o → output log file
