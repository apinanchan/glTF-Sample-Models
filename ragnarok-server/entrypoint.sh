#!/bin/bash
set -e

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-ragnarok}"
DB_PASSWORD="${DB_PASSWORD:-ragnarok}"
DB_NAME="${DB_NAME:-ragnarok}"

echo "==> Configuring database connection..."

# Update inter_athena.conf with environment variables
sed -i \
    -e "s|login_server_ip:.*|login_server_ip: ${DB_HOST}|g" \
    -e "s|login_server_port:.*|login_server_port: ${DB_PORT}|g" \
    -e "s|login_server_id:.*|login_server_id: ${DB_USER}|g" \
    -e "s|login_server_pw:.*|login_server_pw: ${DB_PASSWORD}|g" \
    -e "s|login_server_db:.*|login_server_db: ${DB_NAME}|g" \
    -e "s|char_server_ip:.*|char_server_ip: ${DB_HOST}|g" \
    -e "s|char_server_port:.*|char_server_port: ${DB_PORT}|g" \
    -e "s|char_server_id:.*|char_server_id: ${DB_USER}|g" \
    -e "s|char_server_pw:.*|char_server_pw: ${DB_PASSWORD}|g" \
    -e "s|char_server_db:.*|char_server_db: ${DB_NAME}|g" \
    -e "s|map_server_ip:.*|map_server_ip: ${DB_HOST}|g" \
    -e "s|map_server_port:.*|map_server_port: ${DB_PORT}|g" \
    -e "s|map_server_id:.*|map_server_id: ${DB_USER}|g" \
    -e "s|map_server_pw:.*|map_server_pw: ${DB_PASSWORD}|g" \
    -e "s|map_server_db:.*|map_server_db: ${DB_NAME}|g" \
    -e "s|log_db_ip:.*|log_db_ip: ${DB_HOST}|g" \
    -e "s|log_db_port:.*|log_db_port: ${DB_PORT}|g" \
    -e "s|log_db_id:.*|log_db_id: ${DB_USER}|g" \
    -e "s|log_db_pw:.*|log_db_pw: ${DB_PASSWORD}|g" \
    -e "s|log_db_db:.*|log_db_db: ${DB_NAME}|g" \
    conf/inter_athena.conf

echo "==> Waiting for database to be ready..."
max_attempts=30
attempt=0
until mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" -e "SELECT 1;" "${DB_NAME}" &>/dev/null; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "ERROR: Database not available after ${max_attempts} attempts."
        exit 1
    fi
    echo "  Attempt ${attempt}/${max_attempts}..."
    sleep 3
done

echo "==> Checking if database needs initialization..."
TABLE_COUNT=$(mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" \
    -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}';" -s -N 2>/dev/null || echo "0")

if [ "$TABLE_COUNT" -lt 5 ]; then
    echo "==> Importing rAthena SQL schema..."
    mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" < sql-files/main.sql
    mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" < sql-files/logs.sql

    echo "==> Creating GM admin account (user: admin / pass: admin)..."
    mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" <<SQL
INSERT IGNORE INTO login (userid, user_pass, sex, group_id, state)
VALUES ('admin', MD5('admin'), 'M', 99, 0);
SQL
    echo "==> Database initialized."
else
    echo "==> Database already initialized (${TABLE_COUNT} tables found)."
fi

echo "==> Starting rAthena servers..."
exec ./athena-start start
