#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error: $1"
    # Additional error handling logic can be added here
    exit 1
}

# Install necessary tools
sudo apt update && sudo apt install -y tor curl jq perl git || handle_error "Failed to install necessary tools."

# Check if Nipe is installed
if [ ! -d "$HOME/nipe" ]; then
    echo "Nipe is not installed. Installing Nipe..."
    cd $HOME || handle_error "Failed to change directory to $HOME."
    git clone https://github.com/htrgouvea/nipe || handle_error "Failed to clone Nipe repository."
    cd nipe || handle_error "Failed to change directory to nipe."
else
    echo "Nipe is already installed."
    cd $HOME/nipe || handle_error "Failed to change directory to $HOME/nipe."
fi

# Install required Perl modules
sudo cpan install Switch JSON LWP::UserAgent Config::Simple || handle_error "Failed to install Perl modules."

# Start the Tor service
sudo service tor start || handle_error "Failed to start Tor service."

# Wait for Tor to start
echo "Waiting for Tor to start..."
sleep 10

# Test Tor connection
echo "Testing Tor connection..."
TOR_CHECK=$(curl --socks5 127.0.0.1:9050 -s https://check.torproject.org | grep -o "Congratulations. This browser is configured to use Tor.")

if [ -z "$TOR_CHECK" ]; then
    handle_error "Tor is not configured correctly. Please check your settings."
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
cd $HOME/nipe || handle_error "Failed to change directory to $HOME/nipe."
sudo perl nipe.pl restart || handle_error "Failed to start Nipe."

# Wait for Nipe to establish the connection
sleep 5

# Check Nipe status
NIPE_STATUS=$(sudo perl nipe.pl status | grep -o "activated")

if [ "$NIPE_STATUS" == "activated" ]; then
    echo "Nipe is running."
else
    handle_error "Failed to start Nipe."
fi

echo "Done!"

# Prompt user for website input
read -p "Enter the website you want to access through Tor: " website

# Validate the website URL
if [[ "$website" =~ ^https?:// ]]; then
    echo "Accessing $website through Tor and Nipe..."
    curl --socks5 127.0.0.1:9050 -s "$website"
else
    handle_error "Invalid website URL."
fi

echo "Done!"
