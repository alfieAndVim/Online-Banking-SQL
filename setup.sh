#! /bin/bash
echo "This script will setup the database in a postgres instance"

#check which version of postgres is installed and save to variable
pg_version=$(psql --version | cut -d " " -f 3 | cut -c1-2)
#print out which version of postgres was detected
echo "Postgres version detected: $pg_version"

#add postgres to path
export PATH=$PATH:/usr/lib/postgresql/$pg_version/bin

#check if postgres instance exists inside folder online_banking_instance
if [ -d "online_banking_instance" ]; then
    echo "Postgres instance already exists"
else
    echo "Creating postgres instance"
    #create postgres instance
    initdb -D online_banking_instance
fi


#check if postgres instance online_banking is running
if pgrep -x "postgres" > /dev/null
then
    echo "Postgres instance is running"
else
    echo "Starting postgres instance"
    #start postgres instance
    pg_ctl -D online_banking_instance -l logfile start
fi


#check if database matching online_banking exists
if psql -l | grep -qw online_banking; then
    echo "Database online_banking already exists"
else
    echo "Creating database online_banking"
    #create database online_banking
    createdb online_banking
fi

psql -l | grep online_banking


#check if role postgres exists
if psql -d online_banking -c "\du" | grep -qw postgres; then
    echo "Role postgres already exists"
else
    echo "Creating role postgres"
    #create role postgres with superuser and login privileges
    psql -d online_banking -c "CREATE ROLE postgres WITH SUPERUSER LOGIN CREATEDB CREATEROLE;"
fi
psql -d online_banking -c "GRANT ALL PRIVILEGES ON DATABASE online_banking TO postgres;"
#alter database owner to postgres
psql -d online_banking -c "ALTER DATABASE online_banking OWNER TO postgres;"

#load sql file into database
psql -U postgres -d online_banking -f online_banking.sql