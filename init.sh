#!/bin/bash

echo "kernel.shmmax=2147483648" >> /etc/sysctl.conf

echo "max_connections = 300" >> /var/lib/postgresql/data/postgresql.conf
echo "shared_buffers = 512MB" >> /var/lib/postgresql/data/postgresql.conf
echo "statement_timeout = 10000" >> /var/lib/postgresql/data/postgresql.conf

echo "host all all all scram-sha-256" >> /var/lib/postgresql/data/pg_hba.conf
echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf
echo "host all all ::/0 md5" >> /var/lib/postgresql/data/pg_hba.conf

psql -U postgres -c "REVOKE ALL ON DATABASE postgres FROM PUBLIC;"

INIT_SQL="$(dirname "$0")/init.sql"

if [ ! -f "$INIT_SQL" ]; then
  echo "init.sql not found at $INIT_SQL"
  exit 1
fi

for i in $(seq 1 30); do
  db_name="db$i"
  user_name="team$i"
  user_pass=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c6)

  echo "$user_name : $user_pass"

  psql -U postgres -c "CREATE USER $user_name WITH PASSWORD '$user_pass';"
  psql -U postgres -c "CREATE DATABASE $db_name;"
  psql -U postgres -c "REVOKE ALL ON DATABASE $db_name FROM PUBLIC;"
  psql -U postgres -c "REVOKE ALL ON SCHEMA public FROM PUBLIC;"
  psql -U postgres -c "ALTER DATABASE $db_name OWNER TO $user_name;"
  psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $user_name;"
  psql -U postgres -c "GRANT USAGE ON SCHEMA public TO $user_name;"
  psql -U postgres -c "GRANT CREATE ON SCHEMA public TO $user_name;"
  psql -U postgres -c "GRANT CONNECT ON DATABASE postgres TO $user_name;"
done