#!/bin/bash
#Provided by @sysadzen
#Linux Community

# Tested on Ubuntu 12.04 64bit
echo "Tested on Ubuntu 12.04 64bit"


set -e
# Log Installation.
exec 2> >(tee "/var/log/install_graylog2.err")
exec > >(tee "/var/log/install_graylog2.log")

# Setup Pause function
function pause(){
   read -p "$*"
}
echo "Enter your Network Interface ( ex. eth0 or eth1 then press enter..)"
read interface
echo "You entered $interface ( This is the Interface that is connected to the network)"
pause 'Press [ENTER] key to confirm...'

echo "Detecting YOUR IP Address"
IPADDR="$(ifconfig | grep -A 1 '$interface' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
echo "Detected IP Address is $IPADDR"

IPADD=$IPADDR
HOSTALIAS=$IPADDR

# Install Dependencies
echo "installing prerequisites"
apt-get update
apt-get -y install git curl build-essential  mongodb-server openjdk-7-jre-headless pwgen wget python-software-properties vim uuid-runtime adduser --yes
echo "done..."


# Install elasticsearch-0.90
echo "Downloading and Installing ElasticSearch to /opt Directory Please wait..."
cd /opt
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.10.deb
sudo dpkg -i elasticsearch-0.90.10.deb
sed -i -e 's|# cluster.name: elasticsearch|cluster.name: graylog2-production|' /etc/elasticsearch/elasticsearch.yml
sed -i -e 's|# <http://elasticsearch.org/guide/en/elasticsearch/reference/current/setup-configuration.html>|script.disable_dynamic: true|' /etc/elasticsearch/elasticsearch.yml
sudo /etc/init.d/elasticsearch restart


# Making elasticsearch start on boot
sudo update-rc.d elasticsearch defaults 95 10


echo "Entering APT-KEY"
sudo apt-key adv --keyserver pgp.surfnet.nl --recv-keys 016CFFD0


# Disable CD Sources in /etc/apt/sources.list

echo "adding additional repo"
cd /etc/apt/sources.list.d/
touch added.list
echo 'deb http://finja.brachium-system.net/~jonas/packages/graylog2_repro/ wheezy main' > added.list
apt-get update


echo "Downloading and Installing GrayLog2-Server GrayLog2-Web"
sudo apt-get install graylog2-server graylog2-web graylog2-stream-dashboard --yes

# Configure Graylog2-Server and Graylog2-web
echo "configuring graylog2 server and web on startup."
echo "Installing graylog2-server"
echo -n "Enter your prefered password for the GRAYLOG2 Web Interface: "
read password
echo "You entered $password (MAKE SURE TO NOT FORGET THIS PASSWORD!)"
pause 'Press [Enter] key to continue...'

pass_hash=$(echo -n $password|sha256sum|awk '{print $1}')

sed -i -e 's|root_password_sha2 =|root_password_sha2 = '$pass_hash'|' /etc/graylog2/server/server.conf
sed -i -e 's|RUN=no|RUN=yes|' /etc/default/graylog2-server
sed -i -e 's|RUN=no|RUN=yes|' /etc/default/graylog2-web
sed -i -e 's|#rest_transport_uri = http://192.168.1.1:12900/|rest_transport_uri = http://127.0.0.1:12900/|' /etc/graylog2/server/server.conf
pass_secret=$(pwgen -s 96)
sed -i -e 's|password_secret =|password_secret = '$pass_secret'|' /etc/graylog2/server/server.conf
sed -i -e 's|application.secret=""|application.secret="'$pass_secret'"|' /etc/graylog2/web/graylog2-web-interface.conf
sed -i -e 's|graylog2-server.uris=""|graylog2-server.uris="'http://127.0.0.1:12900/'"|' /etc/graylog2/web/graylog2-web-interface.conf
sed -i -e 's|#elasticsearch_cluster_name = elasticsearch|elasticsearch_cluster_name = graylog2-production|' /etc/graylog2/server/server.conf
sed -i -e 's|#elasticsearch_discovery_zen_ping_multicast_enabled = false|elasticsearch_discovery_zen_ping_multicast_enabled = false|' /etc/graylog2/server/server.conf
sed -i -e 's|#elasticsearch_discovery_zen_ping_unicast_hosts = 192.168.1.203:9300|elasticsearch_discovery_zen_ping_unicast_hosts = 127.0.0.1:9300|' /etc/graylog2/server/server.conf
sed -i -e 's|#elasticsearch_node_name = graylog2|elasticsearch_node_name = graylog2-production|' /etc/graylog2/server/server.conf
sed -i -e 's|# Set both 'bind_host' and 'publish_host':|script.disable_dynamic: true|' /etc/graylog2/server/server.conf
sed -i -e 's|#elasticsearch_index_prefix = graylog2|elasticsearch_index_prefix = graylog2|' /etc/graylog2/server/server.conf
# Restarting GrayLog2 Services
sudo /etc/init.d/graylog2-server restart
sudo /etc/init.d/graylog2-web restart
echo "restarted!"

# Cleaning up /opt
echo "Cleaning Installation Files on /opt"
rm -rf /opt/*

# All Done
echo "Installation has completed!!"
echo "Browse to IP address of this Graylog2 Server Used for Installation"
echo "IP Address detected from system is $IPADDR"
echo "Browse to http://$IPADDR:9000"
echo "Login with username: admin and Login with password: $password"
echo "Browse URL http://$IPADD:9000"
echo "Congratulations We Successfully Installed Graylog2-Server, GrayLog2-Web ElasticSearch and MongoDB"
echo "Linux Community"
echo "@sysadzen"




