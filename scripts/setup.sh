#!/usr/bin/env bash
set -euo pipefail

readonly MIN_UBUNTU="22.04"
readonly APP_USER="deploy"
readonly APP_DIR="/opt/app"

err() { echo "error: $*" >&2; exit 1; }

check_root() {
    [ "$(id -u)" -eq 0 ] || err "run as root"
}

check_os() {
    . /etc/os-release
    [[ "$VERSION_ID" < "$MIN_UBUNTU" ]] && err "Ubuntu $MIN_UBUNTU+ required (got $VERSION_ID)"
}

install_base() {
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
        curl git ufw fail2ban \
        ca-certificates gnupg \
        unattended-upgrades apt-listchanges
}

install_docker() {
    command -v docker &>/dev/null && return
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
}

create_deploy_user() {
    id -u "$APP_USER" &>/dev/null && return
    useradd -m -s /bin/bash -G docker "$APP_USER"
    mkdir -p "/home/$APP_USER/.ssh"
    chmod 700 "/home/$APP_USER/.ssh"
    chown -R "$APP_USER:$APP_USER" "/home/$APP_USER/.ssh"
}

configure_firewall() {
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
}

configure_fail2ban() {
    cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port    = 22
EOF
    systemctl enable --now fail2ban
}

harden_ssh() {
    sed -i \
        -e 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/^#\?PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/^#\?X11Forwarding.*/X11Forwarding no/' \
        /etc/ssh/sshd_config
    sshd -t
    systemctl restart sshd
}

configure_auto_updates() {
    cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF
    systemctl enable --now unattended-upgrades
}

setup_app_dir() {
    mkdir -p "$APP_DIR"
    chown "$APP_USER:$APP_USER" "$APP_DIR"
}

main() {
    check_root
    check_os
    install_base
    install_docker
    create_deploy_user
    configure_firewall
    configure_fail2ban
    harden_ssh
    configure_auto_updates
    setup_app_dir
    echo "done. add your public key: /home/$APP_USER/.ssh/authorized_keys"
}

main "$@"
