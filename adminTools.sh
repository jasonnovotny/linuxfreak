#!/bin/bash
#set -x
#set -e

#Clearing the current console window
printf "\033c"

################################################
# SETTING COLOR OPTIONS
################################################
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
GREEN=$(tput setaf 2)
CYAN=$(tput setaf 6)
BLACK=$(tput setaf 0)
LIME_YELLOW=$(tput setaf 190)
YELLOW=$(tput setaf 3)
POWDER_BLUE=$(tput setaf 153)
MAGENTA=$(tput setaf 5)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)

#eye catching options
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)
################################################
################################################
# INITIALIZE CERTAIN ARRAYS & VARIABLES
################################################
# declare an associative array for the create a user function to reference key:value pairs
declare -A usrName

################################################
# CHECK PRE-REQS
################################################
#script must be run as root
function chk_root {
	if [[ $EUID -ne 0 ]]; then
		echo "${RED}\nThis script must be run as root\n${NORMAL}"
		exit 1
	fi
}

#verify an internet connection is available
function chk_network {
	wget --spider -q --tries=10 --timeout=20 http://google.com 
	if [[ $? -ne 0 ]]; then
		printf "${RED}\nPlease check the network connection\n\n${NORMAL}"
		exit 1
	fi
}
################################################
# FUNCTIONS THAT WILL LATER BE CALLED BY THE MENU
################################################
function add_user {
	read -p "Enter the new users name?: " usrName
	addUserList[u]=$usrName
	#printf "\nUsername: ${addUserList[u]}\n"
	# check username against current system users
	grep -q ${addUserList[u]} /etc/passwd
	if [[ $? -eq 0 ]]; then
		printf "${RED}\nUsername already exists; please try again\n${NORMAL}"
		add_user
	fi
	# check if user home dir should be created
	while true; do
		read -p "Should a home directory created for ${addUserList[u]} (y/n)?: " usrHomeDir
		# add answer to array in case needed later
		queryUserHome[h]=$usrHomeDir
		case $usrHomeDir in
			[Yy]* )
				useradd -m ${addUserList[u]};
				break;;
			[Nn]* )
				useradd -M ${addUserList[u]};
				break;;
			* ) echo "Please answer yes or no";;
		esac
	done
	# add user to sudoers if needed
	while true; do
		read -p "Should ${addUserList[u]} be added to sudoers (y/n)?: " usrSudoers
		# add answer to array in case needed later
		queryUserHome[s]=$usrSudoers
		case $usrSudoers in
			[Yy]* )
				sed -i -E '/root.*ALL/a  '${addUserList[u]}'    ALL\=\(ALL\)       ALL' /etc/sudoers
				break;;
			[Nn]* )
				break;;
			* ) echo "Please answer yes or no";;
		esac
	done
	# go back to the main menu
	run_menu
}

#function update_password {
#}
################################################
################################################
# MENU
################################################
function run_menu {
	showMenu () {
		printf "\n========================================================\n"
		echo "1) Add a user"
		echo "2) Update a users password"
		echo "3) Exit script"
		printf "\n"
	}
	while [ 1 ]
	do
		showMenu
		read -p "Please choose an option: " -n 1 OPTION
		case "$OPTION" in
			"1")
				printf "\n"
				add_user
				break;;
			"2")
				printf "\n\nplaceholder 2\n\n"
				break;;
			"3")
				printf "\n\n${RED}Exiting...${NORMAL}\n\n"
				exit 2
				break;;
		esac
		printf "\n*** INVALID SELECITON ***\n"
	done
}
################################################
################################################
# FUNCTION CALLS
################################################
chk_root
chk_network
run_menu
exit

