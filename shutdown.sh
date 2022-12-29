#! /bin/bash
echo "This script will shutdown the database in a postgres instance"

#check which version of postgres is installed and save to variable
pg_version=$(psql --version | cut -d " " -f 3 | cut -c1-2)
#print out which version of postgres was detected
echo "Postgres version detected: $pg_version"

#add postgres to path
export PATH=$PATH:/usr/lib/postgresql/$pg_version/bin

#check if postgres instance online_banking is running
if pgrep -x "postgres" > /dev/null
then
    echo "Postgres instance is running"
    pg_ctl -D online_banking_instance -l logfile stop
else
    echo "Postgres instance is not running"
    exit 1
fi

#removes instance directory
rm -r online_banking_instance

#kills postgres processes
sudo pkill -x "postgres"