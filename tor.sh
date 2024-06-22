#!/bin/bash

LOG_FILE="/var/log/tor_setup.log"

cred='\033[1;31m'  # Red color and bold
creset='\033[0m'   # Reset color and style

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
    
    if curl -s https://check.torproject.org | grep -q "Congratulations"; then
        tor_info=$(curl -s "https://ipapi.co/${current_ip}/json/")
        tor_country=$(echo $tor_info | jq -r .country_name)
        tor_city=$(echo $tor_info | jq -r .city)
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

# Function to perform remote login and check remote server IP
remote_login_and_check() {
    local remote_ip="192.168.88.28"
    local remote_user="tc"
    local remote_password="tc"

    log_message "Attempting to log in to remote server $remote_ip..."
    
    if sshpass -p "$remote_password" ssh -o StrictHostKeyChecking=no "$remote_user@$remote_ip" '
        echo "Remote login successful"
        remote_ip=$(curl -s https://api.ipify.org)
        remote_country=$(curl -s https://ipapi.co/${remote_ip}/country_name/)
        echo "Remote Server IP: $remote_ip"
        echo "Remote Server Country: $remote_country"
    '; then
        log_message "Remote login successful and IP info retrieved"
        return 0
    else
        log_message "Remote login failed"
        return 1
    fi
}

# Function to visit website through Tor
visit_website() {
    local website=$1
    log_message "Attempting to visit $website through Tor..."
    curl --socks5 localhost:9050 -s "$website" > /dev/null
    if [ $? -eq 0 ]; then
        log_message "Successfully visited $website through Tor."
    else
        log_message "Failed to visit $website through Tor."
    fi
}

# Check if required packages are installed
required_packages=(tor curl git build-essential libssl-dev libcurl4-openssl-dev libnet-ssleay-perl perl cpanminus geoip-bin whois sshpass)
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
    log_message "Tor is functioning correctly. Proceeding to website visit."
else
    log_message "Tor configuration check failed. Proceeding to website visit anyway."
fi

# Ask user for website input
read -p "Enter a website to visit through Tor (include http:// or https://): " website
#visit_website "$website"

# Attempt remote login and check remote server IP
if remote_login_and_check; then
    log_message "Remote login successful and IP info retrieved. Script execution complete."
else
    log_message "Remote login failed. Script execution complete."
fi

log_message "Script execution finished."