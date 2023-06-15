#!/bin/bash

# Get IPs from terraform output
Nginx_IP_EAST=$(terraform output -raw nginx_east_ip)
Nginx_IP_WEST=$(terraform output -raw nginx_west_ip)

# Interval in seconds
CURL_INTERVAL=5

echo "Nginx address (EAST): $Nginx_IP_EAST"
echo "Nginx address (WEST): $Nginx_IP_WEST"
echo -e "Making requests to Nginx services every $CURL_INTERVAL seconds.\nPress ctrl+c to quit."

while true; do 
    echo -e "\n\Nginx (EAST) response:"
    curl $Nginx_IP_EAST:19090/coffees; sleep $CURL_INTERVAL; 
    echo -e "\n\nNginx (WEST) response:"
    curl $Nginx_IP_WEST:19090/coffees; sleep $CURL_INTERVAL; 
done