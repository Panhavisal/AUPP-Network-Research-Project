#!/bin/bash

# Install necessary tools
sudo apt update
sudo apt install -y tor curl jq perl git

# Check if Nipe is installed
if [ ! -d "$HOME/nipe" ]; then
    echo "Nipe is not installed. Installing Nipe..."
    cd $HOME
    git clone https://github.com/htrgouvea/nipe
    cd nipe
else
    echo "Nipe is already installed."
    cd $HOME/nipe
fi

# Install required Perl modules
sudo cpan install Switch JSON LWP::UserAgent Config::Simple

# Start the Tor service
sudo service tor start

# Wait for Tor to start
echo "Waiting for Tor to start..."
sleep 10

# Test Tor connection
echo "Testing Tor connection..."
TOR_CHECK=$(curl --socks5 127.0.0.1:9050 -s https://check.torproject.org | grep -o "Congratulations. This browser is configured to use Tor.")

if [ -z "$TOR_CHECK" ]; then
    echo "Tor is not configured correctly. Please check your settings."
    exit 1
else
    echo "Tor is configured correctly."
fi

# Get the Tor IP
TOR_IP=$(curl --socks5 127.0.0.1:9050 -s https://ifconfig.io/ip)
echo "Tor IP: $TOR_IP"

# Fetch country information using ipinfo.io
TOR_COUNTRY=$(curl --socks5 127.0.0.1:9050 -s https://ipinfo.io/$TOR_IP | jq -r '.country')

# If ipinfo.io fails, use ipapi.co as a fallback
if [ -z "$TOR_COUNTRY" ]; then
    echo "ipinfo.io failed, trying ipapi.co..."
    TOR_COUNTRY=$(curl --socks5 127.0.0.1:9050 -s https://ipapi.co/$TOR_IP/country/)
fi

if [ -z "$TOR_COUNTRY" ]; then
    echo "Failed to retrieve the country information."
else
    echo "Tor IP's country: $TOR_COUNTRY"
fi

# Start Nipe
cd $HOME/nipe
sudo perl nipe.pl start

# Wait for Nipe to establish the connection
sleep 5

# Check Nipe status
NIPE_STATUS=$(sudo perl nipe.pl status | grep -o "activated")

if [ "$NIPE_STATUS" == "activated" ]; then
    echo "Nipe is running."
else
    echo "Failed to start Nipe."
    exit 1
fi

# Verify the Nipe connection by checking IP
NIPE_IP=$(curl -s https://ifconfig.io/ip)
NIPE_COUNTRY=$(curl -s https://ipinfo.io/$NIPE_IP | jq -r '.country')

echo "Nipe IP: $NIPE_IP"
echo "Nipe IP's country: $NIPE_COUNTRY"

# Prompt user for website input
read -p "Enter the website you want to access through Tor: " website

# Access the website through Tor and Nipe
echo "Accessing $website through Tor and Nipe..."
curl --socks5 127.0.0.1:9050 -s $website

echo "Done!"
