#!/bin/bash


# We need real IP addresses since /etc/hosts can't alias one domain to another.
DB1_IP=`dig +short db1`
DB2_IP=`dig +short db2`
APP1_IP=`dig +short app1`
APP2_IP=`dig +short app2`

sed -i "s/db1/${DB1_IP}/" /etc/deadpool/pools/mysql.yml
sed -i "s/db2/${DB2_IP}/" /etc/deadpool/pools/mysql.yml
sed -i "s/app1/${APP1_IP}/" /etc/deadpool/pools/mysql.yml
sed -i "s/app2/${APP2_IP}/" /etc/deadpool/pools/mysql.yml

# Is this necessary?
sleep 5

# Setup /etc/hosts on all the app servers
deadpool-admin --start
deadpool-admin --promote_server --pool=mysql --server=primary_host
deadpool-admin --stop
# Start deadpool in the foreground for docker
deadpool-admin --foreground