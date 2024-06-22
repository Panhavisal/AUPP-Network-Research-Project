#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$(dirname "$0")"
LOG_FILE="$SCRIPT_DIR/tor_setup.log"

# Function to log messages
log_message() {
    echo "$(date) - $1" | tee -a "$LOG_FILE"
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
        #tor_country=$(echo $tor_info | jq -r .country_name)
        #tor_city=$(echo $tor_info | jq -r .city)
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
    local whois_file="$(pwd)/${website}_full_whois.txt"
    local nmap_file="$(pwd)/${website}_nmap_result.txt"

    log_message "Attempting to log in to remote server $remote_ip on port $remote_port..."
    
    # Connect to Server B and perform WHOIS lookup
    log_message "Performing WHOIS lookup for $website..."
    sshpass -p "$remote_password" ssh -o StrictHostKeyChecking=no -p $remote_port "$remote_user@$remote_ip" "
        echo 'Remote login successful'
        remote_ip=\$(curl -s https://api.ipify.org)
        remote_country=\$(geoiplookup \$remote_ip | awk '{str=\"\"; for(i=4;i<=NF;i++) str=str\" \"\$i; print str}')
        echo \"Remote Server IP: \$remote_ip\"
        echo \"Remote Server Country: \$remote_country\"
        
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

# Check if required packages are installed
required_packages=(tor curl git build-essential libssl-dev libcurl4-openssl-dev libnet-ssleay-perl perl cpanminus geoip-bin whois sshpass nmap)
for pkg in "${required_packages[@]}"; do
    if ! dpkg -s $pkg &> /dev/null; then
        log_message "$pkg is not installed. Installing..."
        sudo apt update >> "$LOG_FILE" 2>&1
        sudo apt install $pkg -y >> "$LOG_FILE" 2>&1
    fi
done

# Install or update nipe
if [ ! -d "/opt/nipe" ]; then
    log_message "Installing nipe..."
    sudo git clone https://github.com/htrgouvea/nipe /opt/nipe >> "$LOG_FILE" 2>&1
else
    log_message "Updating nipe..."
    cd /opt/nipe
    sudo git pull >> "$LOG_FILE" 2>&1
fi

cd /opt/nipe
sudo cpanm --installdeps . >> "$LOG_FILE" 2>&1
sudo perl nipe.pl install >> "$LOG_FILE" 2>&1

# Ensure Tor service is running
if ! systemctl is-active --quiet tor; then
    sudo systemctl start tor >> "$LOG_FILE" 2>&1
    log_message "Tor service started."
else
    log_message "Tor service is already running."
fi

# Start nipe
log_message "Starting nipe..."
sudo perl /opt/nipe/nipe.pl start >> "$LOG_FILE" 2>&1
sleep 10  # Give nipe some time to initialize

# Check nipe status
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

# Check Tor status once
if check_tor_status; then
    log_message "Tor is functioning correctly. Proceeding to website input."
else
    log_message "Tor configuration check failed. Proceeding to website input anyway."
fi

# Ask user for website input on Server A
read -p "Enter a website to SCAN: " website
log_message "User entered website: $website"

# Attempt remote login, WHOIS lookup, and nmap scan
if remote_login_and_check "$website"; then
    log_message "Remote operations completed successfully. Script execution complete."
else
    log_message "Remote operations failed. Script execution complete."
fi

log_message "Script execution finished."