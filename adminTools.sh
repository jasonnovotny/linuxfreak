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
declare -A addUserList
declare -A delUserList
declare -A userPassMgmtList

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
	#addUserList[a] - users name
	#addUserList[b] - y to create home, n dont create home
	#addUserList[c] - FUTURE FEATURE
	read -p "Enter the new users name?: " usrName
	addUserList[a]=$usrName
	#printf "\nUsername: ${addUserList[a]}\n"
	# check username against current system users
	grep -q ${addUserList[a]} /etc/passwd
	if [[ $? -eq 0 ]]; then
		printf "${RED}\nUsername already exists, please try again\n${NORMAL}"
		add_user
	fi
	# check if user home dir should be created
	while true; do
		read -p "Should a home directory created for ${addUserList[a]} (y/n)?: " usrHomeDir
		# add answer to array in case needed for future features
		addUserList[b]=$usrHomeDir
		case $usrHomeDir in
			[Yy]* )
				useradd -mp ${addUserList[a]};
				break;;
			[Nn]* )
				useradd -Mp ${addUserList[a]};
				break;;
			* ) echo "Please answer yes or no";;
		esac
	done
	# add user to sudoers section
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

function del_user {
	#delUserList[a] - users name
	#delUserList[b] - y to delete home, n dont del home
	read -p "Enter the new users name?: " usrDelName
	delUserList[a]=$usrDelName
	#printf "\nUsername: ${delUserList[a]}\n"
	# check username against current system users
	grep -q ${delUserList[a]} /etc/passwd
	if [[ $? -ne 0 ]]; then
		printf "${RED}\nUser not found, please try again\n${NORMAL}"
		del_user
	fi
	# check if user home dir should be removed
	while true; do
		read -p "Should ${addUserList[a]}'s home directory be deleted (y/n)?: " usrHomeDirDel
		# add answer to array in case needed for future features
		delUserList[b]=$usrHomeDirDel
		case $usrHomeDirDel in
			[Yy]* )
				userdel -rf ${delUserList[a]};
				break;;
			[Nn]* )
				userdel -f ${delUserList[a]};
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
# MENUS
################################################
function user_pass_mgmt {
	# array: userPassMgmtList
	# -d, --delete            delete the password for the named account (root only)
	#-l, --lock              lock the password for the named account (root only)
	#-u, --unlock            unlock the password for the named account (root only)
	#-e, --expire            expire the password for the named account (root only)
	#-f, --force             force operation
	#-x, --maximum=DAYS      maximum password lifetime (root only)
	#-n, --minimum=DAYS      minimum password lifetime (root only)
	#-w, --warning=DAYS      number of days warning users receives before password expiration (root only)
	#-i, --inactive=DAYS     number of days after password expiration when an account becomes disabled (root only)
	#-S, --status            report password status on the named account (root only)
	# 
	# go back to the main menu
	run_menu
}

# MAIN MENU
function run_menu {
	showMenu () {
		printf "\n========================================================\n"
		echo "1) Add a user"
		echo "2) Delete a user"
		echo "3) User password management menu"
		echo "4) Create test Website & DB (ONLY RUN ONCE UNLESS PURGED)"
		echo "5) Purge test website & database"
		echo "6) Exit"
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
				printf "\n"
				del_user
				break;;
			"3")
				printf "\n"
				update_user_pass
				break;;
			"4")
				printf "\n"
				scriptPath=$( find / -name "freakSetup.sh" 2> /dev/null )
				su -c $scriptPath
				break;;
			"5")
				printf "\n"
				#to-do create linuxfreak website cleanup; call script
				run_menu
				break;;
			"6")
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
# many of the other function calls will happen within the run_menu function
run_menu
exit

