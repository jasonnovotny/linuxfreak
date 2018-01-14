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
	#nginx will not start until the selinux changes below are made
	#systemctl start nginx.service
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
	# Needed to allow nginx to access the web app files
	ausearch -c 'nginx' --raw | audit2allow -M my-nginx
	semodule -i my-nginx.pp

	#Needed to allow nginx to access the conf.d config files
	ausearch -c 'accounts-daemon' --raw | audit2allow -M my-accountsdaemon
	semodule -i my-accountsdaemon.pp

	#the nginx service will fail to start until
	#after the above selinux changes are made
	#start the service again now and check for failures
	systemctl start nginx.service
	if [ $? != "0" ]; then
		echo -e "\nNginx has failed to start, please review the failure"
		exit 2
	fi
}

function config_mysql {
	echo "installing mysql"
	yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm -y
	yum install mysql-community-server -y

	echo "setting up mysql"
	systemctl start mysqld
	tempPass=$( grep 'temporary password' /var/log/mysqld.log | awk '{ print$11 }' )
	echo -n "Enter your desired MySQL Password [ENTER]: ";read newPassword
	mysqladmin -u root -p"$tempPass" password "$newPassword"
	echo -e "[client]\nuser=root\npassword="$newPassword"" > /root/.my.cnf

	echo "building DB table"
	mysql -e "CREATE DATABASE cust_info"
	mysql -e "CREATE TABLE cust_info.info ( firstname VARCHAR(30), lastname VARCHAR(30), email VARCHAR(30), date DATE );"

	echo "completed mysql setup"
}

# TO-DO: Setup MySQL DB for web app

# PRIMARY FUNCTION CALLS
check_root
check_version
dns_setup
web_svr_setup
config_selinux
config_mysql
# END FUNCTION CALLS
firefox linuxfreak.com&
exit
