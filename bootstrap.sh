#!/usr/bin/env bash

# Based off the tutorial found here:
# https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04

# Root check
# http://stackoverflow.com/a/18216122
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Update software sources and installed software
echo "Updating software..."
apt-get update
apt-get -y upgrade

# Add a new user
echo "Adding a new user..."
echo "New user's name: "
read username

adduser $username
usermod -aG sudo $username

echo "Add an authorized key: "
read key

ssh_dir=/home/$username/.ssh
mkdir $ssh_dir
chmod 700 $ssh_dir
chown $username $ssh_dir

echo $key >> $ssh_dir/authorized_keys
chmod 600 $ssh_dir/authorized_keys
chown $username $ssh_dir/authorized_keys

# Hardening SSH
echo "Hardening SSH..."
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication no/PasswordAuthentication no/g' /etc/ssh/sshd_config
systemctl reload sshd


# Setup firewall
echo "Hardening firewall..."
ufw allow ssh
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw show added
ufw enable


# Timezone
echo "Setting up timezone..."
sudo dpkg-reconfigure tzdata
apt-get install ntp

# Swap file
echo "Setting up swapfile"
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

# Finished
echo "VPS Bootstraped."


