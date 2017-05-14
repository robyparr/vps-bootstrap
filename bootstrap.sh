#!/usr/bin/env bash

# Based off the tutorial found here:
# https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04

# Root check
# http://stackoverflow.com/a/18216122
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

basic_formatting="\e[1;34m"
success_formatting="\e[1;32m"
reset="\e[0m"

echo_formatted() {
  text=$1
  echo -e "$basic_formatting==> $text$reset"
}

echo_success() {
  text=$1
  echo -e "$success_formatting==> $text$reset"
}

# Update software sources and installed software
echo_formatted "Updating software..."
apt-get update
apt-get -y upgrade

# Add a new user
echo_formatted "Adding a new user..."
echo -n "New user's name: "
read username

echo -n "Email: "
read email

# Lowercase the username
# http://stackoverflow.com/a/18801723
username=$(echo "$username" | tr '[:upper:]' '[:lower:]')

adduser $username
usermod -aG sudo $username
echo_success "Added user '$username'."

echo -n "Add an authorized key for $username: "
read key

ssh_dir=/home/$username/.ssh
mkdir $ssh_dir
chmod 700 $ssh_dir
chown $username $ssh_dir

echo $key >> $ssh_dir/authorized_keys
chmod 600 $ssh_dir/authorized_keys
chown $username $ssh_dir/authorized_keys

echo_success "User SSH Key setup."

# Hardening SSH
echo_formatted "Configure SSH..."
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication no/PasswordAuthentication no/g' /etc/ssh/sshd_config
systemctl reload sshd
echo_success "SSH configured."


# Setup firewall
echo_formatted "Configuring firewall..."
ufw allow ssh
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw show added
ufw enable
echo_success "Firewall configured."


# Timezone
echo_formatted "Configuring timezone..."
sudo dpkg-reconfigure tzdata
apt-get install -y ntp
echo_success "Timezone configured."

# Swap file
echo_formatted "Configuring swapfile..."
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
echo_success "Swapfile configured."

#
# Required software
#
echo_formatted "Installing required software..."
# Dokku
wget https://raw.githubusercontent.com/dokku/dokku/v0.9.4/bootstrap.sh -O dokku-bootstrap.sh
DOKKU_TAG=v0.9.4 bash dokku-bootstrap.sh

dokku plugin:install https://github.com/dokku/dokku-mysql.git mysql
dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
git clone https://github.com/dokku/dokku-maintenance.git /var/lib/dokku/plugins/maintenance

# Required software packages
apt-get install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev fail2ban chkrootkit clamav sendmail

# Fail2ban
echo "findtime = 600" > /etc/fail2ban/jail.local
echo "maxretry = 3" >> /etc/fail2ban/jail.local
echo "bantime = 3600" >> /etc/fail2ban/jail.local

echo "gem: --no-document" > ~/.gemrc
gem install bundler

echo_success "Required software installed."

# Crontab
echo_formatted "Configuring scheduled jobs..."
echo "MAILTO=$email" >> /etc/cron.d/custom_tasks
echo "@weekly root /usr/sbin/chkrootkit" >> /etc/cron.d/custom_tasks
echo "@daily root sudo clamscan -ri / 2> /dev/null" >> /etc/cron.d/custom_tasks
echo_success "Scheduled jobs configured."

# Finished
echo "Subject: VPS bootstrapped!" > ~/email
echo "Your VPS has been bootstrapped!" >> ~/email
cat ~/email | sendmail $email
rm ~/email

echo ""
echo_success "VPS Bootstraped <=="


