#!/bin/bash
set -Eeuo pipefail

until pg_isready -t 5 >/dev/null
do
  echo "Waiting for Postgres server $DB_HOST:$DB_PORT..."
  sleep 1
done
