#!/usr/bin/env bash

PG_CONF="/var/lib/pgsql/11/data/postgresql.conf"
PG_HBA="/var/lib/pgsql/11/data/pg_hba.conf"
PG_DIR="/var/lib/pgsql/11/data/"
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'      /" ""
printf "host    all             all             all                     md5" >> ""
