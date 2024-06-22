#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$(dirname "$0")"
LOG_FILE="$SCRIPT_DIR/tor_setup.log"

# Function to log messages
log_message() {
    echo "$(date) - $1" | tee -a "$LOG_FILE"
}

# Function to update GeoIP database
update_geoip_db() {
    log_message "Updating GeoIP database..."
    sudo geoipupdate >> "$LOG_FILE" 2>&1
    log_message "GeoIP database update completed."
}

# Function to check Tor status
check_tor_status() {
    log_message "Checking Tor status..."
    current_ip=$(curl -s https://api.ipify.org)
    current_tor_country=$(geoiplookup $current_ip | awk '{str=""; for(i=4;i<=NF;i++) str=str" "$i; print str}')
    log_message "Current IP: $current_ip"
    log_message "Current Country: $current_tor_country (Local DB)"

    tor_ip_country=$(whois $current_ip | grep -i "country" | tail -n 1 | awk '{print $2}' )

    log_message "Verifying TOR Connection..."

    if curl -s https://check.torproject.org | grep -q "Congratulations"; then
        tor_info=$(curl -s "https://ipapi.co/${current_ip}/json/")
        log_message "Tor is working properly."
        log_message "Tor IP: $current_ip"
        if [ -z "$tor_ip_country" ]; then
            log_message "Current Country: Load Failed (WHOIS)"
        else
            log_message "Current Country: $tor_ip_country (WHOIS)"
        fi
        log_message "Current Country: $current_tor_country (Local DB)"
        return 0
    else
        log_message "Tor configuration check failed."
        return 1
    fi
}

# Function to perform remote login, WHOIS lookup, and nmap scan
remote_login_and_check() {
    local remote_ip="192.168.88.180"
    local remote_port="51322"
    local remote_user="tc"
    local remote_password="tc"
    local website="$1"
     local whois_file="$SCRIPT_DIR/${website}_full_whois.txt"
    local nmap_file="$SCRIPT_DIR/${website}_nmap_result.txt"

    log_message "Attempting to log in to remote server $remote_ip on port $remote_port..."

    # Fetch remote IP and Country
    #remote_info=$(sshpass -p "$remote_password" ssh -o StrictHostKeyChecking=no -p "$remote_port" "$remote_user@$remote_ip" '
    #    echo "Remote login successful"
    #    remote_ip=$(curl -s https://api.ipify.org)
    #    remote_country=$(geoiplookup $remote_ip | awk "{str=\"\"; for(i=4;i<=NF;i++) str=str\" \"$i; print str}")
    #    echo "Remote Server IP: $remote_ip"
    #    echo "Remote Server Country: $remote_country"
    #')
    #remote_ip=$(echo "$remote_info" | grep "Remote Server IP" | awk '{print $4}')
    #remote_country=$(geoiplookup $remote_ip | awk '{str=""; for(i=4;i<=NF;i++) str=str" "$i; print str}')
    #echo "Remote IP fetched: $remote_ip"
    #echo "Remote Server Country: $remote_country"

    log_message "Hostname for WHOIS and nmap: $website"

    sshpass -p "$remote_password" ssh -o StrictHostKeyChecking=no -p $remote_port "$remote_user@$remote_ip" "
        echo 'Remote login successful'
        remote_ip=$(curl -s https://api.ipify.org)
        echo "Remote Server IP: $remote_ip"
        remote_country=$(geoiplookup $remote_ip | awk "{str=\"\"; for(i=4;i<=NF;i++) str=str\" \"$i; print str}")
        whois \"$website\"
    " > "$whois_file"
    
    # Check if WHOIS lookup was successful
    if [ $? -eq 0 ] && [ -f "$whois_file" ]; then
        log_message "WHOIS lookup completed and saved successfully."
        log_message "WHOIS file location: $whois_file"
        log_message "WHOIS file size: $(du -h "$whois_file" | cut -f1)"
    else
        log_message "WHOIS lookup failed or file not saved."
        return 1
    fi
    
    # Perform nmap scan
    log_message "Performing nmap scan for $website..."
    sshpass -p "$remote_password" ssh -o StrictHostKeyChecking=no -p $remote_port "$remote_user@$remote_ip" "
        nmap \"$website\"
    " > "$nmap_file"
    
    # Check if nmap scan was successful
    if [ $? -eq 0 ] && [ -f "$nmap_file" ]; then
        log_message "nmap scan completed and saved successfully."
        log_message "nmap result file location: $nmap_file"
        log_message "nmap file size: $(du -h "$nmap_file" | cut -f1)"
        return 0
    else
        log_message "nmap scan failed or file not saved."
        return 1
    fi
}

# Install necessary packages on local server
log_message "Checking and installing necessary packages on local server..."
packages=( "curl" "geoip-bin" "whois" "nmap" "sshpass" "jq" "geoipupdate" )
for pkg in "${packages[@]}"; do
    if dpkg -l | grep -qw "$pkg"; then
        log_message "$pkg is already installed."
    else
        log_message "Installing $pkg..."
        sudo apt update >> "$LOG_FILE" 2>&1
        sudo apt install $pkg -y >> "$LOG_FILE" 2>&1
        log_message "$pkg installation completed."
    fi
done

# Update GeoIP database on local server
update_geoip_db

# Check for and install/update nipe on local server
if [ ! -d "/opt/nipe" ]; then
    log_message "Nipe is not installed. Installing nipe..."
    sudo git clone https://github.com/htrgouvea/nipe /opt/nipe >> "$LOG_FILE" 2>&1
    log_message "Nipe installation completed."
else
    log_message "Nipe is already installed. Updating nipe..."
    cd /opt/nipe
    sudo git pull >> "$LOG_FILE" 2>&1
    log_message "Nipe update completed."
fi

cd /opt/nipe
sudo cpanm --installdeps . >> "$LOG_FILE" 2>&1
sudo perl nipe.pl install >> "$LOG_FILE" 2>&1

# Ensure Tor service is running on local server
if ! systemctl is-active --quiet tor; then
    log_message "Tor is not running. Starting Tor service..."
    sudo systemctl start tor >> "$LOG_FILE" 2>&1
    log_message "Tor service started."
else
    log_message "Tor service is already running."
fi

# Start nipe on local server
log_message "Starting nipe..."
sudo perl /opt/nipe/nipe.pl start >> "$LOG_FILE" 2>&1
sleep 10  # Give nipe some time to initialize

# Check nipe status on local server
nipe_status=$(sudo perl /opt/nipe/nipe.pl status)
log_message "Nipe status: $nipe_status"

if echo "$nipe_status" | grep -q "true"; then
    log_message "Nipe is active and running."
else
    log_message "Nipe failed to start properly. Attempting to restart..."
    sudo perl /opt/nipe/nipe.pl restart >> "$LOG_FILE" 2>&1
    sleep 10
    nipe_status=$(sudo perl /opt/nipe/nipe.pl status)
    log_message "Nipe status after restart: $nipe_status"
fi

# Check Tor status once on local server
if check_tor_status; then
    log_message "Tor is functioning correctly. Proceeding to website input."
else
    log_message "Tor configuration check failed. Proceeding to website input anyway."
fi

# Ask user for website input on local server
read -p "Enter a website to SCAN: " website
log_message "User entered website: $website"

# Attempt remote login, WHOIS lookup, and nmap scan on remote server
if remote_login_and_check "$website"; then
    log_message "Remote operations completed successfully. Script execution complete."
else
    log_message "Remote operations failed. Script execution complete."
fi

log_message "Script execution finished."
