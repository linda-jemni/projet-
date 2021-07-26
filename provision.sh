#!/bin/sh

##
## Script configuration
##

# Paranoia mode
set -e
set -u

# Initialize variables (do not modify here, fill the .env file instead)
USER_EMAIL=""
USER_NAME=""
GIT_HOST=""
GIT_REPOSITORY=""
LAN_SUFFIX=""
LAN_SUFFIX_DOTTED=""
APT_PROXY_PORT="3142"
HOSTNAME="$(hostname)"

## Verify that the .env file is well-defined
$SHELL /vagrant/validate.sh /vagrant

eval "$(grep '^USER_EMAIL=' /vagrant/.env)"
eval "$(grep '^USER_NAME=' /vagrant/.env)"
eval "$(grep '^GIT_HOST=' /vagrant/.env)"
eval "$(grep '^GIT_REPOSITORY=' /vagrant/.env)"
eval "$(grep '^LAN_SUFFIX=' /vagrant/.env)"
eval "$(grep '^APT_PROXY_PORT=' /vagrant/.env)"

if [ -n "$LAN_SUFFIX" ]; then
	LAN_SUFFIX_DOTTED=".$LAN_SUFFIX"
fi

##
## Base system installation
##

# Force APT to a non-interactive mode
export DEBIAN_FRONTEND=noninteractive

# Update packages catalog & allow release changes
apt-get update --allow-releaseinfo-change

# Auto-detect existing APT-Proxy or Apt Cacher NG on host or gateways 
# for faster provisioning
apt-get install -y auto-apt-proxy

# Install base tools for working
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    git jq \
    curl wget \
    vim nano \
    gnupg2 \
    iputils-ping


## 
## Git Repository setup
##

# Deploy keys on nodes
mkdir -p /root/.ssh
cp /vagrant/githosting_rsa /home/vagrant/.ssh/githosting_rsa
cp /vagrant/githosting_rsa.pub /home/vagrant/.ssh/githosting_rsa.pub

# Setup SSH on node
cat > /home/vagrant/.ssh/config <<-MARK
Host $GIT_HOST
User git
IdentityFile ~/.ssh/githosting_rsa
MARK

# Fix SSH permissions
chmod 0600 /home/vagrant/.ssh/*
chown -R vagrant:vagrant /home/vagrant/.ssh

# Use SSH-AGENT to pre-load keys on login for vagrant user
sed -i \
	-e '/## BEGIN PROVISION/,/## END PROVISION/d' \
	/home/vagrant/.bashrc

cat >> /home/vagrant/.bashrc <<-MARK
## BEGIN PROVISION
eval \$(ssh-agent -s)
ssh-add ~/.ssh/githosting_rsa
## END PROVISION
MARK

# Deploy git repository in vagrant user's home directory
su - vagrant -c "ssh-keyscan $GIT_HOST >> .ssh/known_hosts"
su - vagrant -c "sort -u < .ssh/known_hosts > .ssh/known_hosts.tmp && mv .ssh/known_hosts.tmp .ssh/known_hosts"
GIT_DIR="$(basename "$GIT_REPOSITORY" |sed -e 's/.git$//')" 
if [ ! -d "/home/vagrant/$(basename "$GIT_DIR")" ]; then
    su - vagrant -c "git clone '$GIT_REPOSITORY' '$GIT_DIR'"
fi

# Configure GIT for vagrant user
su - vagrant -c "git config --global user.name '$USER_NAME'"
su - vagrant -c "git config --global user.email '$USER_EMAIL'"


##
## Elastic Search Setup
##
if echo "$HOSTNAME" | grep '^elastic\(-[0-9]*\)\?$' ; then
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" \
		> /etc/apt/sources.list.d/elastic-7.x.list

	apt-get update && sudo apt-get install -y elasticsearch

	# Wait a little more to prevent timeout
	mkdir -p /etc/systemd/system/elasticsearch.service.d
	cat > /etc/systemd/system/elasticsearch.service.d/startup-timeout.conf <<MARK
[Service]
TimeoutStartSec=500
MARK

	systemctl daemon-reload
	systemctl restart elasticsearch
	systemctl status elasticsearch
fi

##
## Kibana Setup
##
if echo "$HOSTNAME" | grep '^kibana\(-[0-9]*\)\?$'; then
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" \
		> /etc/apt/sources.list.d/elastic-7.x.list

	apt-get update && sudo apt-get install -y kibana

	systemctl restart kibana
	systemctl status kibana
fi

##
## Logstash Setup
##
if echo "$HOSTNAME" | grep '^logstash\(-[0-9]*\)\?$'; then
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" \
		> /etc/apt/sources.list.d/elastic-7.x.list

	apt-get update && sudo apt-get install -y logstash

	systemctl restart logstash
	systemctl status logstash
fi

##
## App Setup
##
if echo "$HOSTNAME" | grep '^app\(-[0-9]*\)\?$'; then
	OLDPWD="$(pwd)"
	apt-get update && sudo apt-get install -y apache2 php7.3
	
	rm -fr /var/www/html 
	mkdir /var/www/html
	cd /var/www/html

	curl -sSL https://download.dokuwiki.org/src/dokuwiki/dokuwiki-2020-07-29.tgz \
		| tar xzvf - --strip-components=1
	
	chown -R www-data:www-data /var/www/html
fi


echo "SUCCESS."

