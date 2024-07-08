# Network Reconnaissance Script (nr.sh)

## Introduction

This bash script, `nr.sh`, is a comprehensive network reconnaissance tool designed to perform various security checks and gather information about specified websites. It utilizes Tor for anonymity and includes features for both local and remote operations.

## Features

- Tor network connectivity check and setup
- GeoIP database update
- Installation and configuration of Nipe (Tor routing tool)
- Remote server login and operations
- WHOIS lookup
- Nmap scanning
- Logging of all operations

## What it Does

1. Sets up and verifies Tor connectivity on the local machine
2. Updates GeoIP database for accurate location information
3. Installs and configures Nipe for improved anonymity
4. Performs a remote login to a specified server
5. Conducts a WHOIS lookup for a user-specified website
6. Executes an Nmap scan on the target website
7. Logs all operations and results for later analysis

## Prerequisites

- Ubuntu or Debian-based Linux distribution
- Superuser (sudo) access
- Internet connection
- The following packages (script will attempt to install if missing):
  - curl
  - geoip-bin
  - whois
  - nmap
  - sshpass
  - jq
  - geoipupdate
  - tor
- Perl with Config::Simple module
- Access to a remote server (for remote operations)

## How to Use

1. Clone this repository or download the `nr.sh` script.
2. Make the script executable:
   ```
   chmod +x nr.sh
   ```
3. Run the script with sudo privileges:
   ```
   sudo ./nr.sh
   ```
4. Follow the prompts to enter the target website for scanning.
5. Review the logs in the script directory for detailed output.

## Sample Output

```less
2024-06-24 10:15:30 - Script execution started.
2024-06-24 10:15:31 - Checking and installing necessary packages on local server...
2024-06-24 10:15:45 - Updating GeoIP database...
2024-06-24 10:16:00 - Checking Tor status...
2024-06-24 10:16:05 - Current IP: 123.45.67.89
2024-06-24 10:16:06 - Current Country: Netherlands (Local DB)
2024-06-24 10:16:10 - Tor is working properly.
2024-06-24 10:16:15 - Starting nipe...
2024-06-24 10:16:25 - Nipe is active and running.
2024-06-24 10:16:30 - User entered website: example.com
2024-06-24 10:16:35 - Attempting to log in to remote server 192.168.88.180 on port 51322...
2024-06-24 10:16:40 - Performing WHOIS lookup for example.com...
2024-06-24 10:16:50 - WHOIS lookup completed and saved successfully.
2024-06-24 10:16:55 - Performing nmap scan for example.com...
2024-06-24 10:17:30 - nmap scan completed and saved successfully.
2024-06-24 10:17:31 - Remote operations completed successfully. Script execution complete.
2024-06-24 10:17:32 - Script execution finished.
```

## Caution

This tool is intended for ethical use only. Always ensure you have permission to scan and gather information about any target websites or systems.

