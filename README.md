# S35 - Secure Network Configuration Script

## Introduction

Welcome to S35, a Secure Network Configuration Script designed by Elwood. This script is primarily focused on enhancing your network security by automating several crucial tasks including updating GeoIP databases, checking the status of the Tor network, and performing remote logins, WHOIS lookups, and nmap scans. The script also ensures that the Tor service is configured correctly and actively running on your system.

## Features

- **Automatic GeoIP Database Update**: Keeps your GeoIP database up-to-date to ensure accurate geolocation information.
- **Tor Network Status Check**: Verifies if the Tor network is functioning correctly by checking your current IP address and country through both local and WHOIS databases.
- **Remote Operations**: Allows remote login to a specified server and performs WHOIS lookups and nmap scans for a given website.
- **Configuration Management**: Ensures that the Tor configuration file (`torrc`) contains the necessary `SocksPort 9050` entry.
- **Nipe Integration**: Installs and manages the Nipe tool to route all traffic through the Tor network.
- **Cool Startup Header**: Displays a colorful and visually appealing startup header using `figlet` and `lolcat`.

## Prerequisites

Ensure that your system has the following packages installed:

- `curl`
- `geoip-bin`
- `whois`
- `nmap`
- `sshpass`
- `jq`
- `geoipupdate`
- `figlet`
- `lolcat`

The script will check for these packages and install them if they are not already present.

## Installation

1. Make the script executable:
    ```bash
    chmod +x nr.sh
    ```

2. Run the script:
    ```bash
    ./nr.sh
    ```

## Usage

Upon running the script, it will:

1. Display a cool startup header with the name "S35", your name, and the script title.
2. Check and install the necessary packages.
3. Update the GeoIP database.
4. Ensure that the Tor configuration file (`torrc`) includes `SocksPort 9050`.
5. Check the status of the Tor network.
6. Install and start Nipe to route traffic through the Tor network.
7. Prompt you to enter a website to scan, then perform a remote login, WHOIS lookup, and nmap scan on the specified website.

## Example Output

```plaintext
*****************************************************
*                                                   *
*                      S35                          *
*           Secure Network Configuration            *
*                                                   *
*****************************************************
Name: Elwood
Script Title: Remote Scanner
***********************************

Checking and installing necessary packages on local server...
Updating GeoIP database...
Checking if SocksPort 9050 is in torrc...
SocksPort 9050 is already present in torrc.
Checking Tor status...
Tor is working properly.
Nipe is active and running.
Enter a website to SCAN: example.com
Performing WHOIS lookup for example.com...
WHOIS lookup completed and saved successfully.
Performing nmap scan for example.com...
nmap scan completed and saved successfully.
Remote operations completed successfully. Script execution complete.
