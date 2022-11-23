#!/bin/bash
user=`whoami`

path=/home/$user/.bashrc
# if the bashrc file exists, read it for existing aliases
if [ -f "$path" ]; then
	while read line; do
		if [[ $line == *"supo="* ]]; then
			toRead=""
			# alias supo="psql -h bebat-test.cbw8hoqlkogf.eu-central-1.rds.amazonaws.com -U postgres -d postgres"
			for part in $line; do
				if [[ $part == "-U" ]]; then
					toRead="user"
				elif [[ $part == "-d" ]]; then
					toRead="database"
				elif [[ $part == "-h" ]]; then
					toRead="url"
				elif [[ $toRead == "user" ]]; then
					adminuser=`echo $part | sed 's/"//g'`
					toRead=""
				elif [[ $toRead == "database" ]]; then
					database=`echo $part | sed 's/"//g'`
					toRead=""
				elif [[ $toRead == "url" ]]; then
					url=`echo $part | sed 's/"//g'`
					toRead=""
				fi
			done
		fi
	done <$path
fi

if [ -z "$url" ]; then
	echo -n "The database connection string: "
	read url
else
	echo "Connecting to url: $url"
fi

if [ -z "$database" ]; then
	echo -n "The database name: "
	read database
else
	echo "With database name: $database"
fi

if [ -z "$adminuser" ]; then
	echo -n "The admin user: "
	read adminuser
else
	echo "With admin user: $adminuser"
fi

echo -n "The administrative password? "
read -s adminpassword
echo ""

echo -n "The new schema to be created: "
read schema

if [ -z "$schema" ]; then
	echo "Did not fill in a schema"
	exit 0
fi
if [ -z "$adminpassword" ]; then
	echo "Did not fill in an admin password"
	exit 0
fi

password=`tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_{|}~' </dev/urandom | head -c 15; echo`

PGPASSWORD=$adminpassword psql -h $url -U $adminuser -d $database -c "CREATE USER $schema WITH PASSWORD '$password'"
PGPASSWORD=$adminpassword psql -h $url -U $adminuser -d $database -c "GRANT CREATE ON DATABASE $database TO $schema"

PGPASSWORD=$password psql -h $url -U $schema -d $database -c "CREATE SCHEMA $schema authorization $schema"
# this is for future tables
PGPASSWORD=$password psql -h $url -U $schema -d $database -c "ALTER DEFAULT PRIVILEGES IN SCHEMA $schema GRANT ALL ON TABLES TO $schema"

printf "\nalias supo-$schema=\"psql -h $url -U $schema -d $database\"" >> ~/.bashrc

echo "Generated with password: $password"

