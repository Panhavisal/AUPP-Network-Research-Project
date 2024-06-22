#!/bin/bash

LOG_FILE="/var/log/tor_setup.log"

# Function to log messages
log_message() {
    echo "$(date) - $1" | tee -a "$LOG_FILE"
}

#New
# Function to check Tor status
check_tor_status() {
    log_message "Checking Tor status..."
    current_ip=$(curl -s https://api.ipify.org)
    current_tor_country=$(geoiplookup $current_ip | awk '{print $4$5}')
    log_message "Current IP: $current_ip"
    log_message "Current Country: $current_tor_country (Local DB)"

    #Custom
    html_content=$(curl -s "https://whatismyipaddress.com/ip/$current_ip")
    tor_ip_country=$(whois $current_ip | grep -i "country" | awk '{print $2}')
    #tor_country_full=$(echo "$html_content" | grep -oP '<th>Country:</th><td>\K[^<]*')
    
    if curl -s https://check.torproject.org | grep -q "Congratulations"; then
        tor_info=$(curl -s "https://ipapi.co/${current_ip}/json/")
        tor_country=$(echo $tor_info | jq -r .country_name)
        tor_city=$(echo $tor_info | jq -r .city)
        log_message "Tor is working properly."
        log_message "Tor IP: $current_ip"
        log_message "Tor IP: $tor_ip_country"
        #log_message "Tor Country: $tor_ip_country"
        #log_message "Tor Location: $tor_city, $tor_country"
        return 0
    else
        log_message "Tor configuration check failed."
        return 1
    fi
}

# Check if required packages are installed
for pkg in tor curl git build-essential libssl-dev libcurl4-openssl-dev libnet-ssleay-perl perl cpanminus; do
    if ! dpkg -s $pkg &> /dev/null; then
        log_message "$pkg is not installed. Installing..."
        sudo apt update >> "$LOG_FILE" 2>&1
        sudo apt install $pkg -y >> "$LOG_FILE" 2>&1
    fi
done

# Install nipe if not already installed
if [ ! -d "/opt/nipe" ]; then
    log_message "Installing nipe..."
    sudo git clone https://github.com/htrgouvea/nipe /opt/nipe >> "$LOG_FILE" 2>&1
    cd /opt/nipe
    sudo cpanm --installdeps . >> "$LOG_FILE" 2>&1
    sudo perl nipe.pl install >> "$LOG_FILE" 2>&1
else
    log_message "Updating nipe..."
    cd /opt/nipe
    sudo git pull >> "$LOG_FILE" 2>&1
    sudo cpanm --installdeps . >> "$LOG_FILE" 2>&1
    sudo perl nipe.pl install >> "$LOG_FILE" 2>&1
fi

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

echo "Initial Tor setup complete. Entering monitoring mode..."
log_message "Entering monitoring mode."

# Main loop to keep the script running and check Tor status
while true; do
    if check_tor_status; then
        log_message "Tor is functioning correctly. Waiting for 5 minutes before next check..."
        sleep 300  # Wait for 5 minutes
    else
        log_message "Attempting to restart nipe..."
        sudo perl /opt/nipe/nipe.pl restart >> "$LOG_FILE" 2>&1
        log_message "Nipe restarted."
        sleep 30  # Wait for 30 seconds before rechecking
    fi
done
