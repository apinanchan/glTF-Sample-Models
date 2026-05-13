#!/bin/bash
# ============================================================
# rAthena Private Server Setup Script
# Episode 21 | Class 4 (4th Jobs) | Max Level 275/60
# ============================================================

set -e

RATHENA_DIR="$HOME/rathena"
DB_NAME="ragnarok"
DB_USER="ragnarok"
DB_PASS="ragnarok"
DB_HOST="127.0.0.1"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── 1. Install dependencies ──────────────────────────────────
install_deps() {
    info "Installing build dependencies..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y \
            git build-essential gcc g++ \
            libmariadb-dev libmariadb-dev-compat \
            zlib1g-dev libpcre3-dev make \
            mariadb-server mariadb-client
    elif command -v yum &>/dev/null; then
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y git mariadb-devel zlib-devel pcre-devel mariadb-server
    else
        error "Unsupported package manager. Install dependencies manually."
    fi
    info "Dependencies installed."
}

# ── 2. Setup MariaDB ─────────────────────────────────────────
setup_database() {
    info "Setting up MariaDB..."
    sudo systemctl start mariadb 2>/dev/null || sudo service mysql start 2>/dev/null || true

    sudo mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" 2>/dev/null
    sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null
    sudo mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'${DB_HOST}';" 2>/dev/null
    sudo mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';" 2>/dev/null
    sudo mysql -e "FLUSH PRIVILEGES;" 2>/dev/null

    info "Database '${DB_NAME}' ready."
}

# ── 3. Clone rAthena ─────────────────────────────────────────
clone_rathena() {
    if [ -d "$RATHENA_DIR" ]; then
        warn "rAthena directory already exists at ${RATHENA_DIR}. Pulling latest..."
        git -C "$RATHENA_DIR" pull
    else
        info "Cloning rAthena..."
        git clone https://github.com/rathena/rathena.git "$RATHENA_DIR"
    fi
}

# ── 4. Patch source for level 275 ────────────────────────────
patch_source() {
    info "Patching MAX_LEVEL to 300 (supports level 275)..."
    local core_hpp="$RATHENA_DIR/src/config/core.hpp"
    if grep -q "MAX_LEVEL" "$core_hpp"; then
        sed -i 's/#define MAX_LEVEL\s\+[0-9]\+/#define MAX_LEVEL 300/' "$core_hpp"
        info "MAX_LEVEL patched."
    else
        warn "MAX_LEVEL not found in core.hpp - may already be set correctly."
    fi
}

# ── 5. Build rAthena ─────────────────────────────────────────
build_rathena() {
    info "Compiling rAthena (this may take 5-10 minutes)..."
    cd "$RATHENA_DIR"
    ./configure --enable-renewal
    make server -j"$(nproc)"
    info "Build complete."
}

# ── 6. Apply custom configuration ────────────────────────────
apply_config() {
    info "Applying private server configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    cp "$SCRIPT_DIR/conf/inter_athena.conf"       "$RATHENA_DIR/conf/inter_athena.conf"
    cp "$SCRIPT_DIR/conf/char_athena.conf"        "$RATHENA_DIR/conf/char_athena.conf"
    cp "$SCRIPT_DIR/conf/login_athena.conf"       "$RATHENA_DIR/conf/login_athena.conf"
    cp "$SCRIPT_DIR/conf/map_athena.conf"         "$RATHENA_DIR/conf/map_athena.conf"
    cp "$SCRIPT_DIR/conf/battle/player.conf"      "$RATHENA_DIR/conf/battle/player.conf"
    cp "$SCRIPT_DIR/conf/battle/exp.conf"         "$RATHENA_DIR/conf/battle/exp.conf"
    cp "$SCRIPT_DIR/conf/battle/misc.conf"        "$RATHENA_DIR/conf/battle/misc.conf"

    info "Configuration files applied."
}

# ── 7. Import SQL schema ──────────────────────────────────────
import_sql() {
    info "Importing database schema..."
    cd "$RATHENA_DIR"

    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < sql-files/main.sql
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < sql-files/logs.sql

    info "Creating GM account (user: admin / pass: admin)..."
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
INSERT IGNORE INTO login (userid, user_pass, sex, group_id, state)
VALUES ('admin', MD5('admin'), 'M', 99, 0);
SQL
    info "SQL schema imported."
}

# ── 8. Configure import override folder ──────────────────────
setup_import_folder() {
    mkdir -p "$RATHENA_DIR/conf/import"
    # Create empty import files if they don't exist
    for f in login_conf char_conf map_conf player_conf exp_conf misc_conf; do
        touch "$RATHENA_DIR/conf/import/${f}.txt"
    done
}

# ── Main ─────────────────────────────────────────────────────
main() {
    echo ""
    echo "============================================================"
    echo " Ragnarok Online Private Server Setup"
    echo " Episode 21 | Class 4 (4th Jobs) | Max Level 275/60"
    echo "============================================================"
    echo ""

    install_deps
    setup_database
    clone_rathena
    patch_source
    build_rathena
    apply_config
    setup_import_folder
    import_sql

    echo ""
    info "Setup complete!"
    echo ""
    echo "To start the server:"
    echo "  cd ${RATHENA_DIR}"
    echo "  ./athena-start start"
    echo ""
    echo "Server ports:"
    echo "  Login Server : 6900"
    echo "  Char Server  : 6121"
    echo "  Map Server   : 5121"
    echo ""
    echo "GM account: admin / admin (group_id 99)"
    echo ""
    echo "Point your client to: 127.0.0.1:6900"
    echo "============================================================"
}

main "$@"
