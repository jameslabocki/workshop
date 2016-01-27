#!/usr/bin/env bash

# Define a unique identifier for the stack
UUID=$(uuidgen | cut -c1-4)
UUID=psql-$UUID

# Delete existing Heat templates that may be outdated and download a new one
rm -f /tmp/postgres*
wget https://raw.githubusercontent.com/rdoxenham/workshop/master/heat-postgres/postgres.yaml \
       	-O /tmp/postgres.yaml > /dev/null 2>&1

# Create the Heat stack - Ansible needs to provide the instance size, as well as PostgreSQL user/pass and database
heat --os-username rdo --os-password redhat \
        --os-tenant-name workshop --os-auth-url http://localhost:5000/v2.0 \
        stack-create -f /tmp/postgres.yaml -P \
       	"instance_type=${1};pgsql_user=${2};pgsql_pass=${3};pgsql_db=${4}" $UUID > /dev/null 2>&1

# Check to see that the Heat stack has been created successfully
heat --os-username rdo --os-password redhat --os-tenant-name workshop \
        --os-auth-url http://localhost:5000/v2.0 stack-show $UUID | \
        grep -i create_complete > /dev/null 2>&1

# Whilst it's not created, keep running the command until it succeeds
while [ $? -ne 0 ]; do
    heat --os-username rdo --os-password redhat --os-tenant-name workshop \
    	--os-auth-url http://localhost:5000/v2.0 stack-show $UUID | \
        grep -i create_complete > /dev/null 2>&1
done

# We should now have the Heat stack created, return the floating IP to Ansible
heat --os-username rdo --os-password redhat --os-tenant-name workshop --os-auth-url http://localhost:5000/v2.0 output-show $UUID --all | grep output_value | awk 'BEGIN { FS = ":" } ; { print $2 }' | sed -e s/\"//g -e s/\,//g -e "s/ //g" | tr -d '\r\n'