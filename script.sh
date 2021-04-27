#!/bin/bash

# Clear screen
clear

# Interception Ctrl+C
trap end 2

# Main menu
function main {
	if [ "$(rpm -qa | grep -o postgresql | wc -l)" -eq "0" ]; then
		echo -en '\e[0m'; read -p $'\e[0mPostgreSQL server is \e[31mnot installed\e[0m, should I install it now? \e[4m[Yy/Nn]\e[24m: \e[33m' answer
		if [[ "$answer" = "Y" || "$answer" = "y" ]]; then install; fi
		if [[ "$answer" = "N" || "$answer" = "n" ]]; then end; fi
	else
		echo -en '\e[0m'; read -p $'\e[0mPostgreSQL server \e[31minstalled\e[0m, uninstall it now? \e[4m[Yy/Nn]\e[24m: \e[33m' answer
		if [[ "$answer" = "Y" || "$answer" = "y" ]]; then remove; fi
		if [[ "$answer" = "N" || "$answer" = "n" ]]; then
			echo -en '\e[0m'; read -p $'\e[0mCreate database and user? \e[4m[Yy/Nn]\e[24m: \e[33m' answer
			if [[ "$answer" = "Y" || "$answer" = "y" ]]; then create_db_user; fi
			if [[ "$answer" = "N" || "$answer" = "n" ]]; then end; fi
		fi
	fi
	main
	}

function install {
	# Install the repository RPM
	echo -en '\e[0mInstalling the repository RPM...'
	sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm > /dev/null 2>&1
	echo -e '\e[32mDone!\e[0m'

	# Disable the built-in PostgreSQL module
	echo -en '\e[0mDisabling the built-in PostgreSQL module...'
	sudo dnf -qy module disable postgresql > /dev/null 2>&1
	echo -e '\e[32mDone!\e[0m'

	# Install PostgreSQL
	echo -en '\e[0mInstalling PostgreSQL...'
	sudo dnf install -y postgresql13-server > /dev/null 2>&1
	echo -e '\e[32mDone!\e[0m'

	# Optionally initialize the database and enable automatic start
	echo -en '\e[0mInitialization the database and enabling automatic start...'
	sudo /usr/pgsql-13/bin/postgresql-13-setup initdb > /dev/null 2>&1
	sudo systemctl enable postgresql-13 > /dev/null 2>&1
	sudo systemctl start postgresql-13 > /dev/null 2>&1
	echo -e '\e[32mDone!\e[0m'

}

function remove {
	# Remove PostgreSQL
	echo -en '\e[0mRemoving PostgreSQL...'
	sudo dnf remove -y postgresql\* > /dev/null 2>&1
	echo -e '\e[32mDone!\e[0m'
	echo -en '\e[0mRemoving the psql directory...'
	rm -rf /var/lib/pgsql > /dev/null 2>&1
	echo -e '\e[32mDone!\e[0m'
}

function create_db_user {
	echo -en '\e[0m'; read -p $'Please enter the database: \e[33m' database
	echo -en '\e[0m'; read -p $'Please enter the username: \e[33m' username
	echo -en '\e[0m'; read -p $'Please enter the password: \e[33m' password
		# Optionally change port the PostgreSQL server
	echo -en '\e[0m'; read -p $'\e[0mChange default PostgreSQL port (5432)? \e[4m[Yy/Nn]\e[24m: \e[33m' answer
	if [[ "$answer" = "Y" || "$answer" = "y" ]]; then echo -en '\e[0m'; read -p $'Please enter the port: \e[33m' port; fi
	if [[ "$answer" = "N" || "$answer" = "n" ]]; then port=5432; fi
	sudo sed -i -e 's/#port = 5432/port = '$port'/' /var/lib/pgsql/13/data/postgresql.conf > /dev/null 2>&1
	sudo systemctl restart postgresql-13 > /dev/null 2>&1

	echo -en '\e[0mCreating a database named \e[31m'$database'\e[0m...'
	sudo -i -u postgres psql -p $port -c 'CREATE DATABASE '$database';' > /dev/null 2>&1
	echo -e '\e[32mDone!\e[0m'
	echo -en '\e[0mCreate a user with the name \e[31m'$username'\e[0m and password \e[31m'$password'\e[0m...'
	sudo -i -u postgres psql -p $port -c 'CREATE USER '$username' WITH ENCRYPTED PASSWORD '\'$password\'';' > /dev/null 2>&1
	echo -e '\e[32mDone!\e[0m'
	echo -en '\e[0mOpening access for the user named \e[31m'$username'\e[0m to the database named \e[31m'$database'\e[0m...'
	sudo -i -u postgres psql -p $port -c 'GRANT ALL PRIVILEGES ON DATABASE '$database' TO '$username';' > /dev/null 2>&1
	echo -e '\e[32mDone!\e[0m'
}

function end {
	echo; echo -e '\e[0mClosing the script...\e[32mAll the best!\e[0m'; exit 1
}

main