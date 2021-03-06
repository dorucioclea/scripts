#!/bin/bash
#
#Izoox.com
#David Scalf 
#Izoox Ansible AWX Master Install
#Installs all prerequisites for Ansible and AWX. Creates Docker
#compose file based on user input. Creates NGINX reverse proxy
#with letsencrypt for ssl.
#

#Disclaimer
DISCLAIMER='###Please ensure that you are runnoing this script locally and that you have configured DNS for you domain prior to continuing.###'
echo $DISCLAIMER
function pause(){
   read -p "$*"
}
pause 'Press [Enter] to continue...'

#User input
echo 'What is the FQDN of your AWX Server?'
read FQDN
echo "what is the admin email for your domain's ssl cert?"
read CONTACT
HOST=${FQDN%%.*} 
DOMAIN=${FQDN#*.} 


#Prepare to install stuff
apt update -y
apt install -y apt-transport-https ca-certificates curl software-properties-common 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-add-repository --yes "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-add-repository --yes ppa:ansible/ansible
add-apt-repository --yes universe
apt update -y
apt dist-upgrade -y
apt install -y docker-ce docker-ce-cli
apt install -y python python-simplejson python-pip python-software-properties
apt install -y openssl
apt install -y git wget ansible
pip install docker-py
curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#Do some initial configuring mosh tmux ufw 
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 60000:61000/udp
systemctl enable ufw
systemctl start ufw
systemctl enable docker
systemctl start docker

#Generate some passwords
SECRETKEY=$(openssl rand -hex 32)
POSTGRESPASS=$(openssl rand -hex 32)
RABBITPASS=$(openssl rand -hex 32)

#Get AWX stuffs
mkdir -p /var/AWX
chmod 0555 /var/AWX
curl -L "https://raw.githubusercontent.com/dscalf23/scripts/master/AWX.yml" -o /var/AWX/AWX.yml

#Edit AWX Config
#sed -i 's/CONTACT/'"$CONTACT"'/g; s/DOMAIN/'"$FQDN"'/g; s/SECRETKEY/'"$SECRETKEY"'/g; s/POSTGRESPASS/'"$POSTGRESPASS"'/g; s/RABBITPASS/'"$RABBITPASS"'/g;' /var/AWX/AWX.yml

#Start DOCKER-COMPOSE
docker-compose -f /var/AWX/AWX.yml up -d

#Ansible Notes
echo "Your Domain Name: "$FQDN
echo "Ansible Secret Key: "$SECRETKEY
echo "Ansible PostgreSQL User: awx"
echo "Ansible PostgreSQL Pass: "$POSTGRESPASS
echo "Ansible RabbitMQ User: awx"
echo "Ansible RabbitMQ Pass: "$RABBITPASS
echo "Ansible AWX Default User: admin"
echo "Ansible AWX Default User: password"
echo "Everything should be golden now!"
