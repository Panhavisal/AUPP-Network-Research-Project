# Remote Server Scan Script

This script is designed to perform WHOIS lookups and nmap scans on a remote server. The results of these operations are saved in the same directory where the script is executed. The script also updates the GeoIP database and checks the status of the Tor service.

## Prerequisites

Before running the script, ensure that the following packages are installed on your local server:

- `curl`
- `geoip-bin`
- `whois`
- `nmap`
- `sshpass`
- `jq`
- `geoipupdate`

You can install these packages using the script itself, which will check and install any missing packages.

## How It Works

1. **Updating GeoIP Database**: The script updates the GeoIP database to ensure accurate location information.
2. **Checking Tor Status**: The script verifies if the Tor service is running and functioning correctly.
3. **Remote Login and Operations**: The script logs into a remote server using `sshpass`, performs a WHOIS lookup, and executes an nmap scan on the specified website.
4. **Saving Results**: The results of the WHOIS lookup and nmap scan are saved in the same directory where the script is executed.

## Usage

1. Clone the repository:

   ```sh
   git clone https://github.com/yourusername/repo-name.git
   cd repo-name
