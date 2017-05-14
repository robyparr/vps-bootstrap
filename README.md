# vps-bootstrap
A simple VPS bootstrap script for quick setup of my VPS.

## Included in bootstrap
* Update software
* Adds non-root user
* Hardens SSH config
* Configures firewall
* Configures timezone
* Configures SWAP (1G)
* Installs software
* Setup scheduled maintenance


## Installed software
* Dokku
* ClamAV
* fail2ban
* chkrootkit

## Scheduled maintenance
* Rootkit scan (chkrootkit)
* Virus scan (clamav)