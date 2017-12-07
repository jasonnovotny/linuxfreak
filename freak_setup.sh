#!/bin/bash
#set -x
#set -e

echo "Setting up LinuxFreak.com test web-server and database.."

# Must run script as root
function check_root {
	if [ $EUID -ne 0 ]; then
    		echo -e "\nScript not running as root, exiting setup"
    		exit 2
	fi
}

# Check for CentOS7/Red Hat
function check_version {
	grep "Red Hat" /proc/version
	if [ $? != "0" ]; then
		echo -e "\nCentOS / Red Hat system not detected, exiting setup"
		exit 2
	fi
}

function dns_setup {
	echo "127.0.0.1   linuxfreak.com www.linuxfreak.com" >> /etc/hosts
}

function web_svr_setup {
	# nginx install/setup sourced from: https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-7
	# Add EPEL repo
	yum install epel-release -y
	yum install nginx -y
	systemctl start nginx.service
	systemctl enable nginx.service
	firewall-cmd --permanent --zone=public --add-service=http 
	firewall-cmd --permanent --zone=public --add-service=https
	firewall-cmd --reload

	#Default server root: /usr/share/nginx/html
	#Defualt server block config file: /etc/nginx/conf.d/default.conf
	#Additional server blocks, known as Virtual Hosts in Apache,
	# can be added by creating new conf files in /etc/nginx/conf.d.
	# Files that end with .conf in that directory will be loaded when Nginx is started.
	# The main Nginx configuration file is located at: /etc/nginx/nginx.conf

	cp -rf linuxfreak.com /usr/share/nginx
	cp -f conf_files/linuxfreak.com.conf /etc/nginx/conf.d
	chown -R nginx. /usr/share/nginx/linuxfreak.com
	chmod -R 755 /usr/share/nginx/linuxfreak.com
	systemctl reload nginx.service
}

# Configure SeLinux
function config_selinux {
	#this change does not take effect until the system is rebooted
	#sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

	#The above code will disable selinux but the objective here is
	#to understand, configure, and utilize SELinux so it has been
	#commented out to force the objective
	ausearch -c 'nginx' --raw | audit2allow -M my-nginx
	semodule -i my-nginx.pp
	#the nginx service will fail to start until
	#after the above changes selinux changes are made
	#start the service again now and check for failures
	systemctl start nginx.service
	if [ $? != "0" ]; then
		echo -e "\nNginx has failed to start, please review the failure"
		exit 2
	fi
}

# Setup MySQL DB for web app

# PRIMARY FUNCTION CALLS
check_root
check_version
dns_setup
web_svr_setup
config_selinux
