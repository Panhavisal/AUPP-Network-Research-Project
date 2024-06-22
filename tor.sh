#!/bin/bash

# Install necessary tools
sudo apt update
sudo apt install -y tor curl jq

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
