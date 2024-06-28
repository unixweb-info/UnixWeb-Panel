#!/bin/bash
# Author: Kriachko Aleksei
# Creation date: 06/21/2024
: '
Welcome to your servers LEMP control panel! The LEMP stack, consisting of Linux, Nginx, MySQL, and PHP, is a powerful combination of software that can power your web applications.
Linux, the operating system, provides a robust and secure environment for your applications. Nginx, the web server, efficiently handles your HTTP requests and serves your web pages. MySQL, the database management system, stores and manages your websites data. Lastly, PHP, the programming language, creates dynamic web applications.
With this LEMP control panel, you can easily manage and monitor your LEMP stack. You can start, stop, and restart services, manage databases, monitor server load and resource usage, and much more. Its designed to make managing your web server as easy as possible.
Remember, a well-managed LEMP stack can provide a fast, secure, and reliable platform for your web applications. Enjoy using your LEMP control panel!
'

function error_exit() {
    echo -e "\e[31mError: $1\e[0m" >&2
    exit 1
}

function check_os() {
    supported_os=("CentOS Stream 9" "AlmaLinux 9\.[0-9] \(Seafoam Ocelot\)" "Rocky Linux 9\.[0-9] \(Blue Onyx\)")
    current_os=$(cat /etc/*release | grep '^PRETTY_NAME=' | cut -d '=' -f 2 | tr -d '"')
    for os in "${supported_os[@]}"; do
        if [[ "$current_os" =~ $os ]]; then
            return 0
        fi
    done
    error_exit "Your operating system is not supported by this script."
}

if [ "$(id -u)" != "0" ]; then
   error_exit "This script must be run as the root user."
fi

check_os

# Function to display the header and project information
function display_header() {
    echo -e "################################################################################
\e[1;32m        _   _       _     __        __   _       ____                  _\e[0m
\e[1;32m       | | | |_ __ (_)_  _\ \      / /__| |__   |  _ \ __ _ _ __   ___| |\e[0m
\e[1;32m       | | | | '_ \| \ \/ /\ \ /\ / / _ \ '_ \  | |_) / _\` | '_ \ / _ \ |\e[0m
\e[1;32m       | |_| | | | | |>  <  \ V  V /  __/ |_) | |  __/ (_| | | | |  __/ |\e[0m
\e[1;32m        \___/|_| |_|_/_/\_\  \_/\_/ \___|_.__/  |_|   \__,_|_| |_|\___|_|\e[0m

\e[1;36m    Telegram: https://t.me/UnixWebAdmin_info, What's App: +995 593-245-168\e[0m

################################################################################"

    text="Kriachko Aleksei \u00A9 2024 Project https://UnixWeb.info\n"
    indent=14
    printf "%${indent}s" ''
    echo -e "\e[1m$text\e[0m"
}



function display_header_warning() {
    echo -e "################################################################################
\e[1;32m        _   _       _     __        __   _       ____                  _\e[0m
\e[1;32m       | | | |_ __ (_)_  _\ \      / /__| |__   |  _ \ __ _ _ __   ___| |\e[0m
\e[1;32m       | | | | '_ \| \ \/ /\ \ /\ / / _ \ '_ \  | |_) / _\` | '_ \ / _ \ |\e[0m
\e[1;32m       | |_| | | | | |>  <  \ V  V /  __/ |_) | |  __/ (_| | | | |  __/ |\e[0m
\e[1;32m        \___/|_| |_|_/_/\_\  \_/\_/ \___|_.__/  |_|   \__,_|_| |_|\___|_|\e[0m

\e[1;36m    Telegram: https://t.me/UnixWebAdmin_info, What's App: +995 593-245-168\e[0m

################################################################################"
    text1="Kriachko Aleksei \u00A9 2024 Project https://UnixWeb.info\n"
    text2="Sorry, this feature is not currently implemented. It will be added in the near future.\n If you urgently need information security setup, please contact me at the contact details above.\n"
    indent=14
    printf "%${indent}s" ''
    echo -e "\e[1m$text1\e[0m"
    echo -e "\e[31m$text2\e[0m"
}

function check_and_run_mariadb() {
    if command -v mysql >/dev/null 2>&1; then
        echo "MariaDB is installed."
        if systemctl is-active --quiet mariadb; then
            echo "MariaDB is running."
            sleep 1
        else
            echo "MariaDB is not running. Starting MariaDB..."
            systemctl start mariadb
            if systemctl is-active --quiet mariadb; then
                echo "MariaDB has been started."
                sleep 1
            else
                echo "Failed to start MariaDB."
                sleep 1
            fi
        fi
    else
        echo "MariaDB is not installed. Installing MariaDB..."
        install_mariadb
    fi
}

check_and_run_mariadb

function add_nginx_repo() {
    local nginx_repo_file="/etc/yum.repos.d/nginx.repo"

    # Check if the Nginx repository is already added
    if [ ! -f "$nginx_repo_file" ]; then
        # Create Nginx repository configuration file
        cat <<EOF > "$nginx_repo_file"
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/rhel/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/rhel/\$releasever/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
        echo -e "\e[32mNginx repository added.\e[0m"
        sleep 3
    else
        echo -e "\e[32mNginx repository already exists, skipping this step.\e[0m"
        sleep 2
    fi
}

#add_nginx_repo

function add_epel_repo() {
    # Checking if the EPEL repository is installed
    if dnf repolist enabled | grep -q "^epel "; then
        echo -e "\e[32mEPEL repository is already installed.\e[0m"
    else
        echo -e "\e[32mInstalling EPEL repository...\e[0m"
        # Installing the EPEL repository
        dnf install -y epel-release
        # System update after adding a new repository
        dnf update -y
        echo -e "\e[32mEPEL repository installed successfully.\e[0m"
    fi
    echo -e "\e[32mReturning to the previous menu...\e[0m"
    sleep 1
}

function create_default_rules() {
echo -e "Main menu > Settings > Security > Firewall (IPTables) > \e[32mCreating Default Rules...\e[0m"
sleep 1
cat << EOF | tee /etc/sysconfig/iptables
# Generated by iptables-save v1.8.10 (nf_tables) on Wed Jun 19 23:43:15 2024
*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:43:15 2024
# Generated by iptables-save v1.8.10 (nf_tables) on Wed Jun 19 23:43:15 2024
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:43:15 2024
# Generated by iptables-save v1.8.10 (nf_tables) on Wed Jun 19 23:43:15 2024
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [261:38561]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
# Completed on Wed Jun 19 23:43:15 2024
# Generated by iptables-save v1.8.10 (nf_tables) on Wed Jun 19 23:43:15 2024
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:43:15 2024
EOF
systemctl restart iptables
cat << EOF | tee /etc/sysconfig/ip6tables
# Generated by ip6tables-save v1.8.10 (nf_tables) on Wed Jun 19 23:56:57 2024
*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:56:57 2024
# Generated by ip6tables-save v1.8.10 (nf_tables) on Wed Jun 19 23:56:57 2024
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:56:57 2024
# Generated by ip6tables-save v1.8.10 (nf_tables) on Wed Jun 19 23:56:57 2024
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p ipv6-icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
-A INPUT -d fe80::/64 -p udp -m udp --dport 546 -m state --state NEW -j ACCEPT
-A INPUT -j REJECT --reject-with icmp6-adm-prohibited
-A FORWARD -j REJECT --reject-with icmp6-adm-prohibited
COMMIT
# Completed on Wed Jun 19 23:56:57 2024
# Generated by ip6tables-save v1.8.10 (nf_tables) on Wed Jun 19 23:56:57 2024
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:56:57 2024
EOF
systemctl restart ip6tables
echo -e "\e[32mDefault rules created!\e[0m"
sleep 3
}

function install_iptables() {
    echo "Installing iptables..."
    dnf update -y
    systemctl disable firewalld
    systemctl stop firewalld
    dnf install iptables-services -y
# Save the current iptables configuration to a variable
IPTABLES_CONFIG=$(cat << EOF
# Generated by iptables-save v1.8.10 (nf_tables) on Wed Jun 19 23:20:21 2024
*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:20:21 2024
# Generated by iptables-save v1.8.10 (nf_tables) on Wed Jun 19 23:20:21 2024
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:20:21 2024
# Generated by iptables-save v1.8.10 (nf_tables) on Wed Jun 19 23:20:21 2024
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:20:21 2024
# Generated by iptables-save v1.8.10 (nf_tables) on Wed Jun 19 23:20:21 2024
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:20:21 2024
EOF
)

# Pass the iptables configuration to iptables-restore
echo "$IPTABLES_CONFIG" | iptables-restore
# Save the current iptables configuration to a variable
IP6TABLES_CONFIG=$(cat << EOF
# Generated by ip6tables-save v1.8.10 (nf_tables) on Wed Jun 19 23:52:18 2024
*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:52:18 2024
# Generated by ip6tables-save v1.8.10 (nf_tables) on Wed Jun 19 23:52:18 2024
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:52:18 2024
# Generated by ip6tables-save v1.8.10 (nf_tables) on Wed Jun 19 23:52:18 2024
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:52:18 2024
# Generated by ip6tables-save v1.8.10 (nf_tables) on Wed Jun 19 23:52:18 2024
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
# Completed on Wed Jun 19 23:52:18 2024
EOF
)

# Pass the iptables configuration to iptables-restore
echo "$IP6TABLES_CONFIG" | ip6tables-restore
    echo "ip6tables has been installed."
    echo -e "\e[31mThe server is unprotected, all ports are open, enable default policies!\e[0m"
    read -p "Enable default policy? (y/n): " answer
    if [[ $answer == "y" ]]; then
        create_default_rules
    else
        echo "Continuing without enabling default policy..."
    fi
    sleep 5
}

function check_and_run_iptables() {
    if rpm -q iptables-services >/dev/null 2>&1; then
        echo "iptables-services is installed."
        if systemctl is-active --quiet iptables; then
            echo "iptables is running."
        else
            echo "iptables is not running. Starting iptables..."
            systemctl start iptables
            if systemctl is-active --quiet iptables; then
                echo "iptables has been started."
            else
                echo "Failed to start iptables."
            fi
        fi
    else
        echo "iptables-services is not installed. Installing iptables..."
        install_iptables
    fi
}

check_and_run_iptables


function check_selinux_status() {
    if [ "$(sestatus | grep 'Current mode' | awk '{print $3}')" = "enforcing" ]; then
        setenforce 0
        echo -e "\e[32mSELinux was in enforcing mode. Changed to permissive mode.\e[0m"
    else
        echo -e "\e[31mSELinux is not in enforcing mode. No action taken.\e[0m"
    fi
}

#
echo -e "\e[32mTemporarily set SELinux to Permissive mode\e[0m"
check_selinux_status
sleep 1
# Function to check the existence of the "sites" table
function check_sites_table() {
    local db_file="/root/database.db"
    local table_exists=$(sqlite3 "$db_file" ".tables" | grep -c "sites")

    if [ "$table_exists" -eq 0 ]; then
        echo "Creating 'sites' table..."
        sqlite3 "$db_file" "CREATE TABLE sites (id INTEGER PRIMARY KEY, name TEXT, domain TEXT, cms TEXT);"
        echo "Table 'sites' created successfully."
    fi
}

# shellcheck disable=SC2218
check_sites_table

# Call the function to check and install SQLite3 with the specified language
function check_install_sqlite3() {
    if ! command -v sqlite3 &>/dev/null; then
        echo "SQLite3 is not installed. Installing..."
        dnf install sqlite -y
    else
        echo "SQLite3 is already installed."
    fi
}

# Function to prompt for user input with validation
function prompt_for_input() {
    local prompt_message=$1
    local cancel_message=$2
    local pattern=$3
    local input

    while true; do
        read -p "$prompt_message" input
        if [[ $input =~ $pattern ]]; then
            echo $input
            break
        elif [[ $input == "cancel" ]]; then
            echo -e "$cancel_message"
            exit 0
        else
            echo "Invalid input. Please try again."
        fi
    done
}

# Function to install Fail2Ban
function install_fail2ban() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Install Packages > \e[1mInstall Fail2Ban\e[0m"
    if rpm -q fail2ban &>/dev/null; then
        echo -e "\e[32mFail2Ban is already installed.\e[0m"
        sleep 2
    else
        echo -e "\e[31mFail2Ban is not installed. Installing...\e[0m"
        if dnf update -y && dnf install fail2ban -y; then  # Update all packages and install Fail2Ban
            if ! grep -Fxq "[sshd]\nenabled=true" /etc/fail2ban/jail.d/00-firewalld.conf
            then
                echo -e "\n[sshd]\nenabled=true" >> /etc/fail2ban/jail.d/00-firewalld.conf
            else
                echo "Content already exists"
            fi
            echo -e "\e[32mFail2Ban has been successfully installed.\e[0m"
            if systemctl enable --now fail2ban; then  # Enable and start the Fail2Ban service
                echo -e "\e[32mFail2Ban service has been enabled and started.\e[0m"
                sleep 2
            else
                echo -e "\e[31mFailed to enable and start Fail2Ban service.\e[0m"
                sleep 2
            fi
        else
            echo -e "\e[31mFailed to install Fail2Ban.\e[0m"
            sleep 2
        fi
    fi
}

# Function to remove Fail2Ban
function remove_fail2ban() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Remove Packages > \e[1mRemove Fail2Ban\e[0m"
    if rpm -q fail2ban &>/dev/null; then
        echo -e "\e[31mFail2Ban is installed. Removing...\e[0m"
        if dnf remove -y fail2ban; then  # Remove Fail2Ban package
            echo -e "\e[32mFail2Ban has been successfully removed.\e[0m"
            sleep 2
        else
            echo -e "\e[31mFailed to remove Fail2Ban.\e[0m"
            sleep 2
        fi
    else
        echo -e "\e[32mFail2Ban is not installed, skipping this step.\e[0m"
        sleep 2
    fi
}

create_nginx_conf_d_unixweb_panel_conf() {
    local conf_d_unixweb_panel_conf="/etc/nginx/conf.d/99-unixwebpanel.conf"

    # Create a new file with the required content
    cat <<EOF > "$conf_d_unixweb_panel_conf"
fastcgi_temp_path /var/cache/nginx/fastcgi_temp 1 2;
fastcgi_cache_path /var/cache/nginx/fastcgi_cache levels=1:2 keys_zone=two:60m max_size=256m inactive=24h;
fastcgi_cache_key "$scheme$request_method$host$request_uri";
fastcgi_cache_methods GET HEAD;
fastcgi_cache_min_uses 2;

open_file_cache max=100000 inactive=20s;
open_file_cache_valid 45s;
open_file_cache_min_uses 2;
open_file_cache_errors on;

fastcgi_send_timeout 3600s;
fastcgi_read_timeout 3600s;
fastcgi_connect_timeout 3600s;
fastcgi_buffer_size   128k;
fastcgi_buffers   4 256k;
fastcgi_busy_buffers_size   256k;

client_body_timeout   1800s;
client_header_timeout      900s;
send_timeout  1800s;
EOF

    echo "$conf_d_unixweb_panel_conf file updated successfully."
}

create_nginx_conf_d_cloudflare() {
    local conf_d_cloudflare_conf="/etc/nginx/conf.d/cloudflare.conf"

    # Create a new file with the required content
    cat <<EOF > "$conf_d_cloudflare_conf"
# https://www.cloudflare.com/ips-v4
set_real_ip_from 173.245.48.0/20;
set_real_ip_from 103.21.244.0/22;
set_real_ip_from 103.22.200.0/22;
set_real_ip_from 103.31.4.0/22;
set_real_ip_from 141.101.64.0/18;
set_real_ip_from 108.162.192.0/18;
set_real_ip_from 190.93.240.0/20;
set_real_ip_from 188.114.96.0/20;
set_real_ip_from 197.234.240.0/22;
set_real_ip_from 198.41.128.0/17;
set_real_ip_from 162.158.0.0/15;
set_real_ip_from 104.16.0.0/13;
set_real_ip_from 104.24.0.0/14;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 131.0.72.0/22;

# https://www.cloudflare.com/ips-v6
set_real_ip_from 2400:cb00::/32;
set_real_ip_from 2606:4700::/32;
set_real_ip_from 2803:f800::/32;
set_real_ip_from 2405:b500::/32;
set_real_ip_from 2405:8100::/32;
set_real_ip_from 2a06:98c0::/29;
set_real_ip_from 2c0f:f248::/32;

real_ip_header X-Forwarded-For;
EOF

    echo "$conf_d_cloudflare_conf file updated successfully."
}

add_deny_all() {
 local nginx_default_conf="/etc/nginx/conf.d/default.conf"
 # Add the line deny all; after server_name localhost;
 sed -i '/server_name  localhost;/a \    deny all;' "$nginx_default_conf"
 echo "The deny all line has been added to the $nginx_default_conf file."
}

replace_nginx_conf() {
    local nginx_conf="/etc/nginx/nginx.conf"
    local backup_conf="/etc/nginx/nginx.conf.old"

    # Create a backup copy of the original file
    mv "$nginx_conf" "$backup_conf"

    # Create a new directory /etc/nginx/modules-enabled
    mkdir -p /etc/nginx/modules-enabled || error_exit "Failed to create directory for nginx modules"

    # Create a new file with the required content
    cat <<EOF > "$nginx_conf"
# this file was autogenerated, please do not edit
user apache;
worker_processes  auto;
worker_rlimit_nofile 200000;
worker_priority -5;
pcre_jit on;

include /etc/nginx/modules-enabled/*.conf;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  2048;
    use epoll;
    multi_accept on;
}

http {
    include	  /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    keepalive_timeout  65;
    client_max_body_size 100m;
    server_tokens	off;
    reset_timedout_connection  on;

    client_body_buffer_size    10K;
    client_header_buffer_size   1k;
    large_client_header_buffers 4 4k;

    sendfile      on;
    aio           on;
    tcp_nopush    on;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*.conf;

    server_names_hash_bucket_size 128;
}
EOF

    echo "$nginx_conf file updated successfully."
    create_nginx_conf_d_unixweb_panel_conf
    create_nginx_conf_d_cloudflare
    add_deny_all
    replace_nginx_service
}

replace_nginx_service() {
# Path to the nginx.service file
nginx_service="/usr/lib/systemd/system/nginx.service"
# Add the line LimitNOFILE=200000 after [Service]
sed -i '/\[Service\]/a LimitNOFILE=200000' "$nginx_service"
echo "LimitNOFILE line added to $nginx_service file."
# Reload systemd manager configuration
systemctl daemon-reload
}

# Function to install Nginx
function install_nginx() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Install Packages > \e[1mInstall Nginx\e[0m"
    if rpm -q nginx &>/dev/null; then
        echo -e "\e[32mNginx is already installed.\e[0m"
    else
        echo -e "\e[31mNginx is not installed. Installing...\e[0m"
        if dnf update -y && dnf install nginx -y; then  # Update all packages and install Nginx
            # Calling the function
            replace_nginx_conf
            echo -e "\e[32mNginx has been successfully installed.\e[0m"
            if systemctl enable --now nginx.service; then  # Enable and start the Nginx service
                echo -e "\e[32mNginx service has been enabled and started.\e[0m"
            else
                echo -e "\e[31mFailed to enable and start Nginx service.\e[0m"
            fi
            mkdir -p /etc/nginx/sites-available  # Create the 'sites-available' directory
            mkdir -p /etc/nginx/sites-enabled  # Create the 'sites-enabled' directory

        else
            echo -e "\e[31mFailed to install Nginx.\e[0m"
        fi
    fi
}

#install_nginx

# Function to remove Nginx
function remove_nginx() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Remove Packages > \e[1mRemove Nginx\e[0m"
    if rpm -q nginx &>/dev/null; then
        echo -e "\e[31mNginx is installed. Removing...\e[0m"
        dnf remove nginx -y  # Remove Nginx
        rm -rf /etc/nginx/*  # Remove all files in the 'nginx' directory
        echo -e "\e[32mNginx has been successfully removed.\e[0m"
    else
        echo -e "\e[32mNginx is not installed. Nothing to remove.\e[0m"
    fi
}

# Function to check and install the Remi repository if it's not already installed
function check_and_install_repo() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mInstall Remi repository\e[0m"
    if [ ! -f /etc/yum.repos.d/remi.repo ]; then
        echo -e "\e[32mThe Remi repository is not installed. Installing...\e[0m"
        dnf install https://rpms.remirepo.net/enterprise/remi-release-9.rpm -y  # Install the Remi repository
        echo -e "\e[32mRemi repository installed successfully.\e[0m"
        sleep 2
    else
        echo -e "\e[32mThe Remi repository is already installed. Continuing...\e[0m"
        sleep 2
    fi
}


# Function to install PHP 7.4
function install_php74() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Install Packages > \e[1mInstall PHP 7.4\e[0m"
    if rpm -q php74 &>/dev/null; then
        echo -e "\e[32mPHP 7.4 is already installed.\e[0m"
    else
        echo -e "\e[31mPHP 7.4 is not installed. Installing...\e[0m"
        dnf update -y  # Update all packages
        check_and_install_repo  # Check and install the repository if it's not already installed
        dnf module reset php -y  # Reset the PHP module
        dnf module enable php:remi-7.4 -y  # Enable PHP 7.4
        # Install PHP 7.4 and related packages
        dnf install php74 php74-php-fpm php74-php-cli php74-php-mysqlnd php74-php-gd php74-php-ldap php74-php-odbc php74-php-pdo php74-php-pear php74-php-xml php74-php-xmlrpc php74-php-mbstring php74-php-snmp php74-php-soap php74-php-zip php74-php-opcache -y
        systemctl enable --now php74-php-fpm.service  # Enable and start the PHP 7.4 service
        echo -e "\e[32mPHP 7.4 has been successfully installed.\e[0m"
        sleep 2
    fi
}


# Function to remove PHP 7.4 if installed
function remove_php74() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Remove Packages > Remove PHP packages > \e[1mRemove PHP 7.4\e[0m"
    # Check if any PHP 7.4 package is installed
    if rpm -q php74 &>/dev/null || rpm -q php74-php-fpm &>/dev/null || rpm -q php74-php-cli &>/dev/null; then
        echo -e "\e[31mPHP 7.4 is installed. Removing...\e[0m"
        dnf module reset php -y  # Reset the PHP module
        dnf module disable php:remi-7.4 -y  # Disable PHP 7.4 module
        # Remove PHP 7.4 and related packages
        dnf remove php74 php74-php-fpm php74-php-cli php74-php-mysqlnd php74-php-gd php74-php-ldap php74-php-odbc php74-php-pdo php74-php-pear php74-php-xml php74-php-xmlrpc php74-php-mbstring php74-php-snmp php74-php-soap php74-php-zip php74-php-opcache -y
        echo -e "\e[32mPHP 7.4 has been successfully removed.\e[0m"
    else
        echo -e "\e[32mPHP 7.4 is not installed. Nothing to remove.\e[0m"
    fi
}


# Function to install PHP 8.0
function install_php80() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Install Packages > \e[1mInstall PHP 8.0\e[0m"
    if rpm -q php80 &>/dev/null; then
        echo -e "\e[32mPHP 8.0 is already installed.\e[0m"
    else
        dnf update -y
        check_and_install_repo
        dnf module reset php -y
        dnf module enable php:remi-8.0 -y
        dnf install php80 php80-php-fpm php80-php-cli php80-php-mysqlnd php80-php-gd php80-php-ldap php80-php-odbc php80-php-pdo php80-php-pear php80-php-xml php80-php-xmlrpc php80-php-mbstring php80-php-snmp php80-php-soap php80-php-zip php80-php-opcache -y
        systemctl enable --now php80-php-fpm.service
        echo -e "\e[32mPHP 8.0 has been successfully installed.\e[0m"
    fi
}

# Function to remove PHP 8.0
function remove_php80() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Remove Packages > Remove PHP packages > \e[1mRemove PHP 8.0\e[0m"
    # Check if any PHP 8.0 package is installed
    if rpm -q php80 &>/dev/null || rpm -q php80-php-fpm &>/dev/null || rpm -q php80-php-cli &>/dev/null; then
        echo -e "\e[31mPHP 8.0 is installed. Removing...\e[0m"
        dnf module reset php -y  # Reset the PHP module
        dnf module disable php:remi-8.0 -y  # Disable PHP 8.0 module
        # Remove PHP 8.0 and related packages
        dnf remove php80 php80-php-fpm php80-php-cli php80-php-mysqlnd php80-php-gd php80-php-ldap php80-php-odbc php80-php-pdo php80-php-pear php80-php-xml php80-php-xmlrpc php80-php-mbstring php80-php-snmp php80-php-soap php80-php-zip php80-php-opcache -y
        echo -e "\e[32mPHP 8.0 has been successfully removed.\e[0m"
    else
        echo -e "\e[32mPHP 8.0 is not installed. Nothing to remove.\e[0m"
    fi
}


# Function to install PHP 8.1
function install_php81() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Install Packages > \e[1mInstall PHP 8.1\e[0m"
    if rpm -q php81 &>/dev/null; then
        echo -e "\e[32mPHP 8.1 is already installed.\e[0m"
    else
        dnf update -y
        check_and_install_repo
        dnf module reset php -y
        dnf module enable php:remi-8.1 -y
        dnf install php81 php81-php-fpm php81-php-cli php81-php-mysqlnd php81-php-gd php81-php-ldap php81-php-odbc php81-php-pdo php81-php-pear php81-php-xml php81-php-xmlrpc php81-php-mbstring php81-php-snmp php81-php-soap php81-php-zip php81-php-opcache -y
        systemctl enable --now php81-php-fpm.service
        echo -e "\e[32mPHP 8.1 has been successfully installed.\e[0m"
    fi
}

# Function to remove PHP 8.1
function remove_php81() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Remove Packages > Remove PHP packages > \e[1mRemove PHP 8.1\e[0m"
    # Check if any PHP 8.1 package is installed
    if rpm -q php81 &>/dev/null || rpm -q php81-php-fpm &>/dev/null || rpm -q php81-php-cli &>/dev/null; then
        echo -e "\e[31mPHP 8.1 is installed. Removing...\e[0m"
        dnf module reset php -y  # Reset the PHP module
        dnf module disable php:remi-8.1 -y  # Disable PHP 8.1 module
        # Remove PHP 8.1 and related packages
        dnf remove php81 php81-php-fpm php81-php-cli php81-php-mysqlnd php81-php-gd php81-php-ldap php81-php-odbc php81-php-pdo php81-php-pear php81-php-xml php81-php-xmlrpc php81-php-mbstring php81-php-snmp php81-php-soap php81-php-zip php81-php-opcache -y
        echo -e "\e[32mPHP 8.1 has been successfully removed.\e[0m"
    else
        echo -e "\e[32mPHP 8.1 is not installed. Nothing to remove.\e[0m"
    fi
}


# Function to install PHP 8.2
function install_php82() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Install Packages > \e[1mInstall PHP 8.2\e[0m"
    if rpm -q php82 &>/dev/null; then
        echo -e "\e[32mPHP 8.2 is already installed.\e[0m"
    else
        dnf update -y
        check_and_install_repo
        dnf module reset php -y
        dnf module enable php:remi-8.2 -y
        dnf install php82 php82-php-fpm php82-php-cli php82-php-mysqlnd php82-php-gd php82-php-ldap php82-php-odbc php82-php-pdo php82-php-pear php82-php-xml php82-php-xmlrpc php82-php-mbstring php82-php-snmp php82-php-soap php82-php-zip php82-php-opcache -y
        systemctl enable --now php82-php-fpm.service
        echo -e "\e[32mPHP 8.2 has been successfully installed.\e[0m"
    fi
}

# Function to remove PHP 8.2
function remove_php82() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Remove Packages > Remove PHP packages > \e[1mRemove PHP 8.2\e[0m"
    # Check if any PHP 8.2 package is installed
    if rpm -q php82 &>/dev/null || rpm -q php82-php-fpm &>/dev/null || rpm -q php82-php-cli &>/dev/null; then
        echo -e "\e[31mPHP 8.2 is installed. Removing...\e[0m"
        dnf module reset php -y  # Reset the PHP module
        dnf module disable php:remi-8.2 -y  # Disable PHP 8.2 module
        # Remove PHP 8.2 and related packages
        dnf remove php82 php82-php-fpm php82-php-cli php82-php-mysqlnd php82-php-gd php82-php-ldap php82-php-odbc php82-php-pdo php82-php-pear php82-php-xml php82-php-xmlrpc php82-php-mbstring php82-php-snmp php82-php-soap php82-php-zip php82-php-opcache -y
        echo -e "\e[32mPHP 8.2 has been successfully removed.\e[0m"
    else
        echo -e "\e[32mPHP 8.2 is not installed. Nothing to remove.\e[0m"
    fi
}


# Function to install PHP 8.3
function install_php83() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Install Packages > \e[1mInstall PHP 8.3\e[0m"
    if rpm -q php83 &>/dev/null; then
        echo -e "\e[32mPHP 8.3 is already installed.\e[0m"
    else
        dnf update -y
        check_and_install_repo
        dnf module reset php -y
        dnf module enable php:remi-8.3 -y
        dnf install php83 php83-php-fpm php83-php-cli php83-php-mysqlnd php83-php-gd php83-php-ldap php83-php-odbc php83-php-pdo php83-php-pear php83-php-xml php83-php-xmlrpc php83-php-mbstring php83-php-snmp php83-php-soap php83-php-zip php83-php-opcache -y
        systemctl enable --now php83-php-fpm.service
        echo -e "\e[32mPHP 8.3 has been successfully installed.\e[0m"
    fi
}

# Function to remove PHP 8.3
function remove_php83() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Remove Packages > Remove PHP packages > \e[1mRemove PHP 8.3\e[0m"
    # Check if any PHP 8.3 package is installed
    if rpm -q php83 &>/dev/null || rpm -q php83-php-fpm &>/dev/null || rpm -q php83-php-cli &>/dev/null; then
        echo -e "\e[31mPHP 8.3 is installed. Removing...\e[0m"
        dnf module reset php -y  # Reset the PHP module
        dnf module disable php:remi-8.3 -y  # Disable PHP 8.3 module
        # Remove PHP 8.3 and related packages
        dnf remove php83 php83-php-fpm php83-php-cli php83-php-mysqlnd php83-php-gd php83-php-ldap php83-php-odbc php83-php-pdo php83-php-pear php83-php-xml php83-php-xmlrpc php83-php-mbstring php83-php-snmp php83-php-soap php83-php-zip php83-php-opcache -y
        echo -e "\e[32mPHP 8.3 has been successfully removed.\e[0m"
    else
        echo -e "\e[32mPHP 8.3 is not installed. Nothing to remove.\e[0m"
    fi
}


# Function to install Let's Encrypt and issue an SSL certificate
function install_letsencrypt() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Install Packages > \e[1mInstall Let's Encrypt\e[0m"
    if rpm -q certbot &>/dev/null; then
        echo -e "\e[32mCertbot is already installed.\e[0m"
    else
        dnf install certbot python3-certbot-nginx -y  # Install certbot and the Nginx plugin for certbot
        #certbot --nginx -d $domain -d www.$domain  # Uncomment this line to issue an SSL certificate for the domain
        # Set up automatic certificate renewal
        echo -e "# Run the certbot jobs\nSHELL=/bin/bash\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\nMAILTO=root\n0 0,12 * * * root /usr/bin/certbot renew --quiet" | tee /etc/cron.d/certbot-renew > /dev/null
        echo -e "\e[32mCertbot has been successfully installed.\e[0m"
    fi
}

# Function to remove Let's Encrypt and issue an SSL certificate
function remove_letsencrypt() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Remove Packages > \e[1mRemove Let's Encrypt\e[0m"
    # Check if certbot or python3-certbot-nginx is installed
    if rpm -q certbot &>/dev/null || rpm -q python3-certbot-nginx &>/dev/null; then
        echo -e "\e[31mLet's Encrypt packages are installed. Removing...\e[0m"
        dnf remove certbot python3-certbot-nginx -y  # Remove certbot and the Nginx plugin for certbot
        rm -rf /etc/cron.d/certbot-renew  # Remove the cron job for certbot renew
        systemctl restart crond.service  # Restart the cron daemon
        echo -e "\e[32mLet's Encrypt packages have been successfully removed.\e[0m"
    else
        echo -e "\e[32mLet's Encrypt packages are not installed. Nothing to remove.\e[0m"
    fi
}


function install_packages_on_first_run() {
    # Run a function check_install_sqlite3
    check_install_sqlite3
    # Run a function check_and_install_repo
    check_and_install_repo
    # Run a function add_nginx_repo
    add_nginx_repo
    # Run a function install_mariadb
    install_mariadb
    # Run a function install_nginx
    install_nginx
    # Run a function install_php74
    install_php74
    # Run a function install_php80
    install_php80
    # Run a function install_php81
    install_php81
    # Run a function install_php82
    install_php82
    # Run a function install_php83
    install_php83
    # Run a function install_letsencrypt
    install_letsencrypt
    # Run a function install_iptables
    install_iptables
    # Run a function install_fail2ban
    install_fail2ban

}

# Check command line arguments
if [ "$1" == "--install" ]; then
     # If the script is launched with the --install parameter, run the install_packages_on_first_run function
     install_packages_on_first_run
fi

# The function 'create_directories' is used to create necessary directories for Nginx configuration.
function create_directories() {
    # Check if the directory '/etc/nginx/sites-available' exists
    if [ ! -d /etc/nginx/sites-available ]; then
        # If the directory does not exist, create it and print a message
        echo -e "\e[32mCreating /etc/nginx/sites-available directory\e[0m"
        mkdir /etc/nginx/sites-available
    else
        # If the directory already exists, print a message
        echo -e "\e[32mDirectory /etc/nginx/sites-available already exists\e[0m"
    fi

    # Check if the directory '/etc/nginx/sites-enabled' exists
    if [ ! -d /etc/nginx/sites-enabled ]; then
        # If the directory does not exist, create it and print a message
        echo -e "\e[32mCreating /etc/nginx/sites-enabled directory\e[0m"
        mkdir /etc/nginx/sites-enabled
    else
        # If the directory already exists, print a message
        echo -e "\e[32mDirectory /etc/nginx/sites-enabled already exists\e[0m"
    fi
}


# Function to create the 'sites' table if it doesn't exist
function create_table_if_not_exists() {
    local sql_query="CREATE TABLE IF NOT EXISTS sites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        domain TEXT NOT NULL,
        cms TEXT NOT NULL
    );"

    # Execute the SQL query to create the table
    sqlite3 /root/database.db "$sql_query"
    if [ $? -eq 0 ]; then
        echo -e "\e[32mTable 'sites' created or already exists\e[0m"
    else
        echo -e "\e[31mFailed to create table 'sites'\e[0m"
    fi
}

# Function to check the existence of the "sites" table
function check_sites_table() {
    local db_file="/root/database.db"
    local table_exists=$(sqlite3 "$db_file" ".tables" | grep -c "sites")

    if [ "$table_exists" -eq 0 ]; then
        echo "Creating 'sites' table..."
        sqlite3 "$db_file" "CREATE TABLE sites (id INTEGER PRIMARY KEY, name TEXT, domain TEXT, cms TEXT);"
        echo "Table 'sites' created successfully."
    fi
}


function create_site_record() {
    local username=$1
    local domain=$2

    #Check for the presence of the "sites" table
     check_sites_table

     # Create an SQL query to add a record
     local sql_query="INSERT INTO sites (name, domain, cms) VALUES ('$username', '$domain', 'WordPress');"

     # Execute the SQL query
    sqlite3 /root/database.db "$sql_query"
    if [ $? -eq 0 ]; then
        echo -e "\e[32mThe record was successfully added to the database\e[0m"
    else
        echo -e "\e[31mFailed to add record to database\e[0m"
    fi
}

# Function to select PHP version
# Call the function
# select_php_version
# Display the selected PHP version
# echo "Selected PHP version: $php_version"
function select_php_version() {
    if [ -z "$php_version" ]; then
        while true; do
            clear  # Clear the screen
            display_header
            echo -e "\e[1mSelection of PHP version\e[0m"
            echo "Available PHP versions:"
            echo "1. PHP 7.4"
            echo "2. PHP 8.0"
            echo "3. PHP 8.1"
            echo "4. PHP 8.2"
            echo "5. PHP 8.3"
            echo "0. Exit"
            read -p "Choose version (0-5): " choice

            case $choice in
                1) php_version="74"; break;;
                2) php_version="80"; break;;
                3) php_version="81"; break;;
                4) php_version="82"; break;;
                5) php_version="83"; break;;
                0) return;;
                *) echo "Invalid choice. Please select from 0 to 5.";;
            esac
        done
    else
        echo "PHP version is already set to $php_version."
    fi
}


function configure_php-fpm_d() {
    mkdir -p /var/www/$username/data/tmp
    chown $username:$username /var/www/$username/data/tmp
    cat << EOF | tee /etc/opt/remi/php$php_version/php-fpm.d/$domain.conf
[$domain]
user = $username
group = $username
listen = /var/opt/remi/php$php_version/run/php-fpm/$domain.sock
listen.owner = $username
listen.group = apache
listen.mode = 0660

pm = dynamic
pm.max_children = 20
pm.min_spare_servers = 6
pm.max_spare_servers = 10
pm.max_requests = 1000
php_admin_value[expose_php] = "0"
php_admin_value[allow_url_fopen] = "1"
php_admin_value[date.timezone] = "Europe/Moscow"
php_admin_value[disable_functions] = "system,shell_exec,passthru,proc_open,popen,expect_popen,pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_signal_get_handler,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,exec,pcntl_exec,pcntl_getpriority,pcntl_setprioritypcntl_async_signals,pcntl_unshare"
php_admin_value[display_errors] = "off"
php_admin_value[log_errors] = "On"
php_admin_value[mail.add_x_header] = "On"
php_admin_value[max_execution_time] = "3600"
php_admin_value[max_input_time] = "3600"
php_admin_value[memory_limit] = "512M"
php_admin_value[max_input_vars] = "100000"
php_admin_value[opcache.blacklist_filename] = "opcache.blacklist_filename=/etc/opt/remi/php$php_version/php.d/opcache*.blacklist"
php_admin_value[opcache.max_accelerated_files] = "100000"
php_admin_value[open_basedir] = "/var/www/$username/data/www/$domain:/var/www/$username/data/tmp"
php_admin_value[output_buffering] = "4096"
php_admin_value[post_max_size] = "100M"
php_admin_value[sendmail_path] = "/usr/sbin/sendmail -t -i -f 'admin@$domain'"
php_admin_value[session.save_path] = "/var/www/$username/data/tmp"
php_admin_value[short_open_tag] = "On"
php_admin_value[upload_max_filesize] = "100M"
php_admin_value[upload_tmp_dir] = "/var/www/$username/data/tmp"


catch_workers_output = no
access.format = "%{REMOTE_ADDR}e - [%t] \"%m %r%Q%q %{SERVER_PROTOCOL}e\" %s %{kilo}M \"%{HTTP_REFERER}e\" \"%{HTTP_USER_AGENT}e\""
access.log = /var/www/$username/data/logs/$domain-backend.access.log
EOF
systemctl restart php$php_version-php-fpm.service
}

# Nginx configuration for various CMS WordPress
function configure_wordpress() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mWebsite WordPress\e[0m"
    select_php_version
    echo "Selected PHP version: $php_version"
    configure_php-fpm_d
    create_directories
    # ...
    cat << EOF | tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    add_header Last-Modified \$date_gmt;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Xss-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;

    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;

    charset off;
    gzip on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/css text/xml application/javascript text/plain application/json image/svg+xml image/x-icon;
    gzip_comp_level 6;

    set \$root_path /var/www/$username/data/www/$domain;
    root \$root_path;
    disable_symlinks if_not_owner from=\$root_path;
    index index.php index.html index.htm;
    #Security for WordPress
    location ~ /(robots.txt|ads.txt) {allow all;}
    location ~ /*\.(json|ini|log|md|txt|sql)|LICENSE {
        # Replace IP 1.2.3.4 with your real IP, if you do not need security, ask your system administrator to delete this configuration.
        allow 1.2.3.4;
        deny all;
    }
    location ~ /\. {
        # Replace IP 1.2.3.4 with your real IP, if you do not need security, ask your system administrator to delete this configuration.
        allow 1.2.3.4;
        deny all;
    }

    location ~* /(?:uploads|wflogs|w3tc-config|files)/.*\.php\$ {
        # Replace IP 1.2.3.4 with your real IP, if you do not need security, ask your system administrator to delete this configuration.
        allow 1.2.3.4;
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~* /wp-includes/.*.php\$ {
        # Replace IP 1.2.3.4 with your real IP, if you do not need security, ask your system administrator to delete this configuration.
        allow 1.2.3.4;
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~* /wp-content/.*.php\$ {
        # Replace IP 1.2.3.4 with your real IP, if you do not need security, ask your system administrator to delete this configuration.
        allow 1.2.3.4;
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~* /themes/.*.php\$ {
        # Replace IP 1.2.3.4 with your real IP, if you do not need security, ask your system administrator to delete this configuration.
        allow 1.2.3.4;
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~* /plugins/.*.php\$ {
        # Replace IP 1.2.3.4 with your real IP, if you do not need security, ask your system administrator to delete this configuration.
        allow 1.2.3.4;
        deny all;
        access_log off;
        log_not_found off;
    }
    location = /xmlrpc.php {
        # Replace IP 1.2.3.4 with your real IP, if you do not need security, ask your system administrator to delete this configuration.
        allow 1.2.3.4;
        deny all;
        access_log off;
        log_not_found off;
    }
    #Security for WordPress admin section
    location ~* ^/(wp-admin/|wp-login\.php) {
        # Replace IP 1.2.3.4 with your real IP and then remove comments to block access to the administrative section of the site for outsiders
        #allow 1.2.3.4;
        #deny all;
        try_files \$uri \$uri/ /index.php?\$args;
    location ~ \.php\$ {
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param SCRIPT_NAME \$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }
    }

    #Yoast SEO Sitemaps
    location ~ ([^/]*)sitemap(.*).x(m|s)l\$ {
      ## this rewrites sitemap.xml to /sitemap_index.xml
      rewrite ^/sitemap.xml\$ /sitemap_index.xml permanent;
      ## this makes the XML sitemaps work
      rewrite ^/([a-z]+)?-?sitemap.xsl\$ /index.php?yoast-sitemap-xsl=$\1 last;
      rewrite ^/sitemap_index.xml\$ /index.php?sitemap=1 last;
      rewrite ^/([^/]+?)-sitemap([0-9]+)?.xml\$ /index.php?sitemap=\$1&sitemap_n=\$2 last;
      ## The following lines are optional for the premium extensions
      ## News SEO
      rewrite ^/news-sitemap.xml\$ /index.php?sitemap=wpseo_news last;
      ## Local SEO
      rewrite ^/locations.kml\$ /index.php?sitemap=wpseo_local_kml last;
      rewrite ^/geo-sitemap.xml\$ /index.php?sitemap=wpseo_local last;
      ## Video SEO
      rewrite ^/video-sitemap.xsl\$ /index.php?yoast-sitemap-xsl=video last;
    }

    location / {
        index index.php index.html;
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location ~ \.php\$ {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
     }


    location ~* ^.+\.(jpg|jpeg|gif|png|svg|js|css|mp3|ogg|mpeg|avi|zip|gz|bz2|rar|swf|ico|7z|doc|docx|map|ogg|otf|pdf|tff|tif|txt|wav|webp|woff|woff2|xls|xlsx|xml)\$ {
        try_files \$uri \$uri/ /index.php?\$args;
        expires 30d;
    }

    location @fallback {
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }
}
server {
    listen 80;
    server_name www.$domain;
    return 301 http://$domain\$request_uri;
    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;
}
EOF
    ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
    nginx -t
    systemctl restart nginx.service
    create_table_if_not_exists
    create_site_record "$username" "$domain"
    echo "The site has been successfully created $domain"
    sleep 3  # Delay for 3 seconds
}

# Nginx configuration for various CMS 1C Bitrix
function configure_bitrix() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mWebsite CMS 1C Bitrix\e[0m"
    select_php_version
    echo "Selected PHP version: $php_version"
    configure_php-fpm_d
    create_directories
    # ...
    cat << EOF | tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    add_header Last-Modified \$date_gmt;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Xss-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;

    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;

    charset off;
    gzip on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/css text/xml application/javascript text/plain application/json image/svg+xml image/x-icon;
    gzip_comp_level 6;

    set \$root_path /var/www/$username/data/www/$domain;
    root \$root_path;
    disable_symlinks if_not_owner from=\$root_path;
    index index.php index.html index.htm;

    location / {
        try_files       \$uri \$uri/ @bitrix;
    }

    location ~* /upload/.*\.(php|php3|php4|php5|php6|phtml|pl|asp|aspx|cgi|dll|exe|shtm|shtml|fcg|fcgi|fpl|asmx|pht|py|psp|rb|var)\$ {
            types {
                    text/plain text/plain php php3 php4 php5 php6 phtml pl asp aspx cgi dll exe ico shtm shtml fcg fcgi fpl asmx pht py psp rb var;
            }
    }

    location ~ \.php\$ {
            try_files       $uri @bitrix;
            fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
            fastcgi_param SCRIPT_FILENAME $document_root\$fastcgi_script_name;
            fastcgi_param PHP_ADMIN_VALUE "sendmail_path = /usr/sbin/sendmail -t -i -f admin@$domain";
            include fastcgi_params;
    }
    location @bitrix {
            fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root/bitrix/urlrewrite.php;
            fastcgi_param PHP_ADMIN_VALUE "sendmail_path = /usr/sbin/sendmail -t -i -f admin@$domain";
    }
    location ~* /bitrix/admin.+\.php\$ {
            try_files       $uri @bitrixadm;
            fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
            fastcgi_param SCRIPT_FILENAME $document_root\$fastcgi_script_name;
            fastcgi_param PHP_ADMIN_VALUE "sendmail_path = /usr/sbin/sendmail -t -i -f admin@$domain";
            include fastcgi_params;
    }
    location @bitrixadm{
            fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root/bitrix/admin/404.php;
            fastcgi_param PHP_ADMIN_VALUE "sendmail_path = /usr/sbin/sendmail -t -i -f admin@$domain";
    }

    location = /favicon.ico {
            log_not_found off;
            access_log off;
    }

    location = /robots.txt {
            allow all;
            log_not_found off;
            access_log off;
    }
    #
    # block this locations for any installation
    #

    # ht(passwd|access)
    location ~* /\.ht  { deny all; }

    # repositories
    location ~* /\.(svn|hg|git) { deny all; }

    # bitrix internal locations
    location ~* ^/bitrix/(modules|local_cache|stack_cache|managed_cache|php_interface) {
      deny all;
    }

    # upload files
    location ~* ^/upload/1c_[^/]+/ { deny all; }

    # use the file system to access files outside the site (cache)
    location ~* /\.\./ { deny all; }
    location ~* ^/bitrix/html_pages/\.config\.php { deny all; }
    location ~* ^/bitrix/html_pages/\.enabled { deny all; }

    # Intenal locations
    location ^~ /upload/support/not_image   { internal; }

    # Cache location: composite and general site
    location ~* @.*\.html$ {
      internal;
      # disable browser cache, php manage file
      expires -1y;
      add_header X-Bitrix-Composite "Nginx (file)";
    }

    # Player options, disable no-sniff
    location ~* ^/bitrix/components/bitrix/player/mediaplayer/player$ {
      add_header Access-Control-Allow-Origin *;
    }

    # Accept access for merged css and js
    location ~* ^/bitrix/cache/(css/.+\.css|js/.+\.js)\$ {
      expires 30d;
      error_page 404 /404.html;
    }

    # Disable access for other assets in cache location
    location ~* ^/bitrix/cache              { deny all; }
    # Static content
    location ~* ^/(upload|bitrix/images|bitrix/tmp) {
      expires 30d;
    }

    location  ~* \.(css|js|gif|png|jpg|jpeg|ico|ogg|ttf|woff|eot|otf)\$ {
      error_page 404 /404.html;
      expires 30d;
    }

    location = /404.html {
            access_log off ;
    }

}

server {
    listen 80;
    server_name www.$domain;
    return 301 http://$domain\$request_uri;
    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;
}
EOF
    ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
    nginx -t
    systemctl restart nginx.service
    create_table_if_not_exists
    create_site_record "$username" "$domain"
    echo "The site has been successfully created $domain"
    sleep 3  # Delay for 3 seconds
}

# Nginx configuration for various CMS Joomla
function configure_joomla() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mWebsite CMS Joomla\e[0m"
    select_php_version
    echo "Selected PHP version: $php_version"
    configure_php-fpm_d
    create_directories
    # ...
    cat << EOF | tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    add_header Last-Modified \$date_gmt;
    # add global x-content-type-options header
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Xss-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;

    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;

    charset off;
    gzip on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/css text/xml application/javascript text/plain application/json image/svg+xml image/x-icon;
    gzip_comp_level 6;

    set \$root_path /var/www/$username/data/www/$domain;
    root \$root_path;
    disable_symlinks if_not_owner from=\$root_path;
    index index.php index.html index.htm default.html default.htm;
    # Support Clean (aka Search Engine Friendly) URLs
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    # deny running scripts inside writable directories
    location ~* /(images|cache|media|logs|tmp)/.*\.(php|pl|py|jsp|asp|sh|cgi)\$ {
        deny all;
    }
    location ~ \.php\$ {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
     }


    # caching of files
    location ~* \.(ico|pdf|flv)\$ {
        expires 1y;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|swf|xml|txt)\$ {
        expires 14d;
    }
}
server {
    listen 80;
    server_name www.$domain;
    return 301 http://$domain\$request_uri;
    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;
}
EOF
    ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
    nginx -t
    systemctl restart nginx.service
    create_table_if_not_exists
    create_site_record "$username" "$domain"
    echo "The site has been successfully created $domain"
    sleep 3  # Delay for 3 seconds
}

# Nginx configuration for various CMS ModX
function configure_modx() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mWebsite CMS ModX\e[0m"
    select_php_version
    echo "Selected PHP version: $php_version"
    configure_php-fpm_d
    create_directories
    # ...
    cat << EOF | tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    add_header Last-Modified \$date_gmt;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Xss-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;

    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;

    charset utf-8;

    gzip on;
    gzip_min_length 1000;
    gzip_proxied any;
    gzip_types text/plain application/xml application/x-javascript text/javascript text/css text/json;
    gzip_disable "MSIE [1-6]\.(?!.*SV1)";
    gzip_comp_level 5;

    set \$root_path /var/www/$username/data/www/$domain;
    root \$root_path;
    disable_symlinks if_not_owner from=\$root_path;
    index index.php index.html index.htm;
    # Redirect from index.php to the site root:
    if ($request_uri ~* '^/index.php\$') {
        return 301 /;
    }

    # Remove repeating slashes from the address
    # Option that only works when merge_slashes = on
    if ($request_uri ~ ^[^?]*//) {
        rewrite ^ $uri permanent;
    }
    # Universal option
    #if ($request_uri ~ ^(?P<left>[^?]*?)//+(?P<right>[^?]*)) {
    #    rewrite ^ $left/$right permanent;
    #}

    # Removing the slash at the end of all URLs, if necessary.
    # If you changed the MODX admin address, you need to specify it in the condition of this rule, otherwise there will be an infinite redirect.
    # if ($request_uri ~ ".*/$") {
    #    rewrite ^/((?!core|connectors|manager|setup).*)/$ /$1 permanent;
    # }

    # Prohibition for all when accessing the MODx core from the browser
    location ~ ^/core/.* {
        deny all;
        return 403;
    }

    location ~ ^/config.core.php {
        return 404;
    }
    location @rewrite {
        rewrite ^/(.*)\$ /index.php?q=$1;
    }
    location / {
        try_files \$uri \$uri/ @rewrite;
    }
    # Basic authorization in service directories
    # You can create a login and password here https://hostingcanada.org/htpasswd-generator/ and add it to the contents of the .htpasswd file
    # If you make several different logins - you need to add them with a new line
    location ~* ^/(manager|connectors)/ {
        #auth_basic "Restricted Access";
        #auth_basic_user_file /var/www/$username/data/www/$domain/.htpasswd;
        try_files \$uri \$uri/ @rewrite;
        location ~ \.php\$ {
            include /etc/nginx/fastcgi_params;
            fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
            fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
            fastcgi_param DOCUMENT_ROOT $realpath_root;
        }
    }
    location ~ \.php\$ {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
    }

    location ~* ^.+\.(jpg|jpeg|gif|png|svg|js|css|mp3|ogg|mpeg|avi|zip|gz|bz2|rar|swf|ico|7z|doc|docx|map|ogg|otf|pdf|tff|tif|txt|wav|webp|woff|woff2|xls|xlsx|xml)\$ {
        try_files $uri @rewrite;
        access_log off;
        expires 10d;
        break;
    }

    location @fallback {
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
	      deny all;
    }

}
server {
    listen 80;
    server_name www.$domain;
    return 301 http://$domain\$request_uri;
    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;
}
EOF
    ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
    nginx -t
    systemctl restart nginx.service
    create_table_if_not_exists
    create_site_record "$username" "$domain"
    echo "The site has been successfully created $domain"
    sleep 3  # Delay for 3 seconds
}

# Nginx configuration for various CMS OpenCart
function configure_opencart() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mWebsite CMS OpenCart\e[0m"
    select_php_version
    echo "Selected PHP version: $php_version"
    configure_php-fpm_d
    create_directories
    # ...
    cat << EOF | tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    add_header Last-Modified \$date_gmt;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Xss-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;
    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains" always;

    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domainerror.log;

    charset off;
    gzip on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/css text/xml application/javascript text/plain application/json image/svg+xml image/x-icon;
    gzip_comp_level 6;

    set \$root_path /var/www/$username/data/www/$domain;
    root \$root_path;
    disable_symlinks if_not_owner from=\$root_path;
    index index.php index.html index.htm;

    location ~* \.(engine|inc|info|install|make|module|profile|test|po|sh|.*sql|theme|tpl(\.php)?|xtmpl)\$|^(\..*|Entries.*|Repository|Root|Tag|Template)\$|\.php_ {
        deny all;
    }

    location / {
        try_files \$uri \$uri/ @opencart;
        location ~* ^.+\.(jpeg|jpg|png|gif|bmp|ico|svg|css|js)\$ {
            expires max;
        }
    }

	  location @opencart {
        rewrite ^/(.+)\$ /index.php?_route_=$1 last;
    }

    location ~ [^/]\.php(/|$) {
            fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
            if (!-f $document_root$fastcgi_script_name) {
                return  404;
            }
            fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
            fastcgi_index   index.php;
            include /etc/nginx/fastcgi_params;
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location ~* "/\.(htaccess|htpasswd)\$" {
        deny    all;
        return  404;
    }
}
server {
    listen 80;
    server_name www.$domain;
    return 301 http://$domain\$request_uri;
    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;
}
EOF
    ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
    nginx -t
    systemctl restart nginx.service
    create_table_if_not_exists
    create_site_record "$username" "$domain"
    echo "The site has been successfully created $domain"
    sleep 3  # Delay for 3 seconds
}

# Nginx configuration for various CMS Drupal
function configure_drupal() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mWebsite CMS Drupal\e[0m"
    select_php_version
    echo "Selected PHP version: $php_version"
    configure_php-fpm_d
    create_directories
    # ...
    cat << EOF | tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    add_header Last-Modified \$date_gmt;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Xss-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;

    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;

    charset off;
    gzip on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/css text/xml application/javascript text/plain application/json image/svg+xml image/x-icon;
    gzip_comp_level 6;

    set \$root_path /var/www/$username/data/www/$domain;
    root \$root_path;
    disable_symlinks if_not_owner from=\$root_path;
    index index.php index.html index.htm;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Very rarely should these ever be accessed outside of your lan
    location ~* \.(txt|log)\$ {
        allow 1.2.3.4;
        deny all;
    }

    location ~ \..*/.*\.php\$ {
        return 403;
    }

    location ~ ^/sites/.*/private/ {
        return 403;
    }

    # Block access to scripts in site files directory
    location ~ ^/sites/[^/]+/files/.*\.php\$ {
        deny all;
    }

    # Allow "Well-Known URIs" as per RFC 5785
    location ~* ^/.well-known/ {
        allow all;
    }

    # Block access to "hidden" files and directories whose names begin with a
    # period. This includes directories used by version control systems such
    # as Subversion or Git to store control files.
    location ~ (^|/)\. {
        return 403;
    }

    location / {
        # try_files $uri @rewrite; # For Drupal <= 6
        try_files $uri /index.php?$query_string; # For Drupal >= 7
    }

    location @rewrite {
        #rewrite ^/(.*)\$ /index.php?q=$1; # For Drupal <= 6
        rewrite ^ /index.php; # For Drupal >= 7
    }

    # Don't allow direct access to PHP files in the vendor directory.
    location ~ /vendor/.*\.php\$ {
        deny all;
        return 404;
    }

    # Protect files and directories from prying eyes.
    location ~* \.(engine|inc|install|make|module|profile|po|sh|.*sql|theme|twig|tpl(\.php)?|xtmpl|yml)(~|\.sw[op]|\.bak|\.orig|\.save)?$|^(\.(?!well-known).*|Entries.*|Repository|Root|Tag|Template|composer\.(json|lock)|web\.config)\$|^#.*#$|\.php(~|\.sw[op]|\.bak|\.orig|\.save)\$ {
        deny all;
        return 404;
    }

    # In Drupal 8, we must also match new paths where the '.php' appears in
    # the middle, such as update.php/selection. The rule we use is strict,
    # and only allows this pattern with the update.php front controller.
    # This allows legacy path aliases in the form of
    # blog/index.php/legacy-path to continue to route to Drupal nodes. If
    # you do not have any paths like that, then you might prefer to use a
    # laxer rule, such as:
    #   location ~ \.php(/|$) {
    # The laxer rule will continue to work if Drupal uses this new URL
    # pattern with front controllers other than update.php in a future
    # release.
    location ~ '\.php\$|^/update.php' {
        fastcgi_split_path_info ^(.+?\.php)(|/.*)\$;
        # Ensure the php file exists. Mitigates CVE-2019-11043
        try_files $fastcgi_script_name =404;
        # Security note: If you're running a version of PHP older than the
        # latest 5.3, you should have "cgi.fix_pathinfo = 0;" in php.ini.
        # See http://serverfault.com/q/627903/94922 for details.
        include /etc/nginx/fastcgi_params;
        # Block httpoxy attacks. See https://httpoxy.org/.
        fastcgi_param HTTP_PROXY "";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param QUERY_STRING $query_string;
        fastcgi_intercept_errors on;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)\$ {
        try_files $uri @rewrite;
        expires max;
        log_not_found off;
    }

    # Fighting with Styles? This little gem is amazing.
    # location ~ ^/sites/.*/files/imagecache/ { # For Drupal <= 6
    location ~ ^/sites/.*/files/styles/ { # For Drupal >= 7
        try_files $uri @rewrite;
    }

    # Handle private files through Drupal. Private file's path can come
    # with a language prefix.
    location ~ ^(/[a-z\-]+)?/system/files/ { # For Drupal >= 7
        try_files $uri /index.php?$query_string;
    }

    # Enforce clean URLs
    # Removes index.php from urls like www.example.com/index.php/my-page --> www.example.com/my-page
    # Could be done with 301 for permanent or other redirect codes.
    if ($request_uri ~* "^(.*/)index\.php/(.*)") {
        return 307 $1$2;
    }
}
server {
    listen 80;
    server_name www.$domain;
    return 301 http://$domain\$request_uri;
    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;
}
EOF
    ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
    nginx -t
    systemctl restart nginx.service
    create_table_if_not_exists
    create_site_record "$username" "$domain"
    echo "The site has been successfully created $domain"
    sleep 3  # Delay for 3 seconds
}

# Nginx configuration for various CMS DataLife
function configure_datalife() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mWebsite CMS DataLife\e[0m"
    select_php_version
    echo "Selected PHP version: $php_version"
    configure_php-fpm_d
    create_directories
    # ...
    cat << EOF | tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    add_header Last-Modified \$date_gmt;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Xss-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;

    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;

    charset off;
    gzip on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/css text/xml application/javascript text/plain application/json image/svg+xml image/x-icon;
    gzip_comp_level 6;

    set \$root_path /var/www/$username/data/www/$domain;
    root \$root_path;
    disable_symlinks if_not_owner from=\$root_path;
    index index.php index.html index.htm;

    location ~* ^/(engine/data|engine/cache|engine/cache/system|language).+\.php {
        deny all;
    }
    location ~* (uploads|uploads/.*|templates|language)/.+\.php {
            deny all;
    }
    location ~ /\.ht {
        deny  all;
    }

    location / {
        rewrite "^/page/([0-9]+)(/?)\$" /index.php?cstart=$1 last;

        rewrite "^/([0-9]{4})/([0-9]{2})/([0-9]{2})/page,([0-9]+),([0-9]+),(.*).html(/?)+$" /index.php?subaction=showfull&year=$1&month=$2&day=$3&news_page=$4&cstart=$5&news_name=$6&seourl=$6 last;
        rewrite "^/([0-9]{4})/([0-9]{2})/([0-9]{2})/page,([0-9]+),(.*).html(/?)+$" /index.php?subaction=showfull&year=$1&month=$2&day=$3&news_page=$4&news_name=$5&seourl=$5 last;
        rewrite "^/([0-9]{4})/([0-9]{2})/([0-9]{2})/print:page,([0-9]+),(.*).html(/?)+$" /engine/print.php?subaction=showfull&year=$1&month=$2&day=$3&news_page=$4&news_name=$5&seourl=$5 last;
        rewrite "^/([0-9]{4})/([0-9]{2})/([0-9]{2})/(.*).html(/?)+$" /index.php?subaction=showfull&year=$1&month=$2&day=$3&news_name=$4&seourl=$4 last;

        rewrite "^/([^.]+)/page,([0-9]+),([0-9]+),([0-9]+)-(.*).html(/?)+$" /index.php?newsid=$4&news_page=$2&cstart=$3&seourl=$5&seocat=$1 last;
        rewrite "^/([^.]+)/page,([0-9]+),([0-9]+)-(.*).html(/?)+$" /index.php?newsid=$3&news_page=$2&seourl=$4&seocat=$1 last;
        rewrite "^/([^.]+)/print:page,([0-9]+),([0-9]+)-(.*).html(/?)+$" /engine/print.php?news_page=$2&newsid=$3&seourl=$4&seocat=$1 last;
        rewrite "^/([^.]+)/([0-9]+)-(.*).html(/?)+$" /index.php?newsid=$2&seourl=$3&seocat=$1 last;

        rewrite "^/page,([0-9]+),([0-9]+),([0-9]+)-(.*).html(/?)+$" /index.php?newsid=$3&news_page=$1&cstart=$2&seourl=$4 last;
        rewrite "^/page,([0-9]+),([0-9]+)-(.*).html(/?)+$" /index.php?newsid=$2&news_page=$1&seourl=$3 last;
        rewrite "^/print:page,([0-9]+),([0-9]+)-(.*).html(/?)+$" /engine/print.php?news_page=$1&newsid=$2&seourl=$3 last;
        rewrite "^/([0-9]+)-(.*).html(/?)+$" /index.php?newsid=$1&seourl=$2 last;

        rewrite "^/([0-9]{4})/([0-9]{2})/([0-9]{2})(/?)+$" /index.php?year=$1&month=$2&day=$3 last;
        rewrite "^/([0-9]{4})/([0-9]{2})/([0-9]{2})/page/([0-9]+)(/?)+$" /index.php?year=$1&month=$2&day=$3&cstart=$4 last;

        rewrite "^/([0-9]{4})/([0-9]{2})(/?)+$" /index.php?year=$1&month=$2 last;
        rewrite "^/([0-9]{4})/([0-9]{2})/page/([0-9]+)(/?)+$" /index.php?year=$1&month=$2&cstart=$3 last;

        rewrite "^/([0-9]{4})(/?)+$" /index.php?year=$1 last;
        rewrite "^/([0-9]{4})/page/([0-9]+)(/?)+$" /index.php?year=$1&cstart=$2 last;

        rewrite "^/tags/([^/]*)(/?)+$" /index.php?do=tags&tag=$1 last;
        rewrite "^/tags/([^/]*)/page/([0-9]+)(/?)+$" /index.php?do=tags&tag=$1&cstart=$2 last;

        rewrite "^/xfsearch/([^/]*)(/?)+$" /index.php?do=xfsearch&xf=$1 last;
        rewrite "^/xfsearch/([^/]*)/page/([0-9]+)(/?)+$" /index.php?do=xfsearch&xf=$1&cstart=$2 last;

        rewrite "^/user/([^/]*)/rss.xml$" /engine/rss.php?subaction=allnews&user=$1 last;
        rewrite "^/user/([^/]*)(/?)+$" /index.php?subaction=userinfo&user=$1 last;
        rewrite "^/user/([^/]*)/page/([0-9]+)(/?)+$" /index.php?subaction=userinfo&user=$1&cstart=$2 last;
        rewrite "^/user/([^/]*)/news(/?)+$" /index.php?subaction=allnews&user=$1 last;
        rewrite "^/user/([^/]*)/news/page/([0-9]+)(/?)+$" /index.php?subaction=allnews&user=$1&cstart=$2 last;
        rewrite "^/user/([^/]*)/news/rss.xml(/?)+$" /engine/rss.php?subaction=allnews&user=$1 last;

        rewrite "^/lastnews(/?)+$" /index.php?do=lastnews last;
        rewrite "^/lastnews/page/([0-9]+)(/?)+$" /index.php?do=lastnews&cstart=$1 last;

        rewrite "^/catalog/([^/]*)/rss.xml$" /engine/rss.php?catalog=$1 last;
        rewrite "^/catalog/([^/]*)(/?)+$" /index.php?catalog=$1 last;
        rewrite "^/catalog/([^/]*)/page/([0-9]+)(/?)+$" /index.php?catalog=$1&cstart=$2 last;

        rewrite "^/newposts(/?)+$" /index.php?subaction=newposts last;
        rewrite "^/newposts/page/([0-9]+)(/?)+$" /index.php?subaction=newposts&cstart=$1 last;

        rewrite "^/favorites(/?)+$" /index.php?do=favorites last;
        rewrite "^/favorites/page/([0-9]+)(/?)+$" /index.php?do=favorites&cstart=$1 last;

        rewrite "^/rules.html$" /index.php?do=rules last;
        rewrite "^/statistics.html$" /index.php?do=stats last;
        rewrite "^/addnews.html$" /index.php?do=addnews last;
        rewrite "^/rss.xml$" /engine/rss.php last;
        rewrite "^/sitemap.xml$" /uploads/sitemap.xml last;

        if (!-d $request_filename) {
                rewrite "^/([^.]+)/page/([0-9]+)(/?)+$" /index.php?do=cat&category=$1&cstart=$2 last;
                rewrite "^/([^.]+)/?$" /index.php?do=cat&category=$1 last;
        }

        if (!-f $request_filename) {
                rewrite "^/([^.]+)/rss.xml$" /engine/rss.php?do=cat&category=$1 last;
                rewrite "^/page,([0-9]+),([^/]+).html$" /index.php?do=static&page=$2&news_page=$1 last;
                rewrite "^/print:([^/]+).html$" /engine/print.php?do=static&page=$1 last;
        }

        if (!-f $request_filename) {
                rewrite "^/([^/]+).html$" /index.php?do=static&page=$1 last;
        }

        location ~* ^.+\.(jpeg|jpg|png|gif|bmp|ico|svg|css|js)\$ {
            expires     max;
        }

        location ~ [^/]\.php(/|$) {
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            if (!-f $document_root$fastcgi_script_name) {
                return  404;
            }

            fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
            fastcgi_index   index.php;
            include         /etc/nginx/fastcgi_params;
        }
    }
}
server {
    listen 80;
    server_name www.$domain;
    return 301 http://$domain\$request_uri;
    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;
}
EOF
    ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
    nginx -t
    systemctl restart nginx.service
    create_table_if_not_exists
    create_site_record "$username" "$domain"
    echo "The site has been successfully created $domain"
    sleep 3  # Delay for 3 seconds
}

# Nginx configuration for various Webasyst CMS (Shop-Script)
function configure_shopscript() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mWebsite Webasyst CMS (Shop-Script)\e[0m"
    select_php_version
    echo "Selected PHP version: $php_version"
    configure_php-fpm_d
    create_directories
    # ...
    cat << EOF | tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    add_header Last-Modified \$date_gmt;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Xss-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;

    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;

    charset off;
    gzip on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/css text/xml application/javascript text/plain application/json image/svg+xml image/x-icon;
    gzip_comp_level 6;

    set \$root_path /var/www/$username/data/www/$domain;
    root \$root_path;
    disable_symlinks if_not_owner from=\$root_path;
    index index.php index.html index.htm;

    try_files \$uri \$uri/ /index.php?\$query_string;

    location /index.php {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
    }

    # for install only
    location /install.php {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
    }

    location /api.php {
        fastcgi_split_path_info  ^(.+\.php)(.*)\$;
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
    }

    location ~ /(oauth.php|link.php|payments.php|captcha.php) {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ^~ /wa-data/protected/ {
        internal;
    }

    location ~ /wa-content {
        allow all;
    }

    location ~ /wa-apps/[^/]+/(plugins/[^/]+/)?(lib|locale|templates)/ {
        deny all;
    }

    location ~ /(wa-plugins/([^/]+)|wa-widgets)/.+/(lib|locale|templates)/ {
        deny all;
    }

    location ~* ^/wa-(cache|config|installer|log|system)/ {
        return 403;
    }

    location ~* ^/wa-data/public/contacts/photos/[0-9]+/ {
        root \$root_path;
        access_log off;
        expires  30d;
        error_page   404  =  @contacts_thumb;
    }

    location @contacts_thumb {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_param  SCRIPT_NAME  /wa-data/public/contacts/photos/thumb.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root/wa-data/public/contacts/photos/thumb.php;
    }

    # photos app
    location ~* ^/wa-data/public/photos/[0-9]+/ {
        access_log   off;
        expires      30d;
        error_page   404  =  @photos_thumb;
    }

    location @photos_thumb {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_param  SCRIPT_NAME  /wa-data/public/photos/thumb.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root/wa-data/public/photos/thumb.php;
    }
    # end photos app

    # shop app
    location ~* ^/wa-data/public/shop/products/[0-9]+/ {
        access_log   off;
        expires      30d;
        error_page   404  =  @shop_thumb;
    }
    location @shop_thumb {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_param  SCRIPT_NAME  /wa-data/public/shop/products/thumb.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root/wa-data/public/shop/products/thumb.php;
    }

    location ~* ^/wa-data/public/shop/promos/[0-9]+ {
        access_log   off;
        expires      30d;
        error_page   404  =  @shop_promo;
    }
    location @shop_promo {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_param  SCRIPT_NAME  /wa-data/public/shop/promos/thumb.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root/wa-data/public/shop/promos/thumb.php;
    }
    # end shop app

    # mailer app
    location ~* ^/wa-data/public/mailer/files/[0-9]+/ {
        access_log   off;
        error_page   404  =  @mailer_file;
    }
    location @mailer_file {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_param  SCRIPT_NAME  /wa-data/public/mailer/files/file.php;
        fastcgi_param  SCRIPT_FILENAME $document_root/wa-data/public/mailer/files/file.php;
    }
    # end mailer app

    location ~* ^.+\.(jpg|jpeg|gif|png|webp|js|css)\$ {
        access_log   off;
        expires      30d;
    }
}
server {
    listen 80;
    server_name www.$domain;
    return 301 http://$domain\$request_uri;
    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;
}
EOF
    echo -e "\nfastcgi_param SCRIPT_FILENAME     \$document_root\$fastcgi_script_name;\nfastcgi_param PATH_INFO           \$fastcgi_path_info;" | tee -a /etc/nginx/fastcgi_params
    ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
    nginx -t
    systemctl restart nginx.service
    create_table_if_not_exists
    create_site_record "$username" "$domain"
    echo "The site has been successfully created $domain"
    sleep 3  # Delay for 3 seconds
}

# Nginx configuration for various UMI.CMS
function configure_umi() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mWebsite UMI.CMS\e[0m"
    select_php_version
    echo "Selected PHP version: $php_version"
    configure_php-fpm_d
    create_directories
    # ...
    cat << EOF | tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    add_header Last-Modified \$date_gmt;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Xss-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;

    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;

    charset off;
    gzip on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/css text/xml application/javascript text/plain application/json image/svg+xml image/x-icon;
    gzip_comp_level 6;

    set \$root_path /var/www/$username/data/www/$domain;
    root \$root_path;
    disable_symlinks if_not_owner from=\$root_path;

    location ~* \/\.ht {
        deny all;
    }

    location ~* ^\/(classes|errors\/logs|sys\-temp|cache|xmldb|static|packages) {
        deny all;
    }

    location ~* (\/for_del_connector\.php|\.ini|\.conf)\$ {
        deny all;
    }

    location ~* ^(\/files\/|\/images\/|\/yml\/) {
        try_files $uri =404;
    }

    location ~* ^\/images\/autothumbs\/ {
        try_files $uri @autothumbs =404;
    }

    location @autothumbs {
        rewrite ^\/images\/autothumbs\/(.*)\$ /autothumbs.php?img=$1$query_string last;
    }

    location @clean_url {
        rewrite ^/(.*)\$ /index.php?path=$1 last;
    }

    location @dynamic {
        try_files $uri @clean_url;
    }

    location \/yml\/files\/ {
        try_files $uri =404;
    }

    location / {
        rewrite ^\/robots\.txt /sbots_custom.php?path=$1 last;
        rewrite ^\/sitemap\.xml /sitemap.php last;
        rewrite ^\/\~\/([0-9]+)\$ /tinyurl.php?id=$1 last;
        rewrite ^\/(udata|upage|uobject|ufs|usel|ulang|utype|umess|uhttp):?(\/\/)?(.*)? /releaseStreams.php?scheme=$1&path=$3 last;
        rewrite ^\/(.*)\.xml$ /index.php?xmlMode=force&path=$1 last;
        rewrite ^(.*)\.json$ /index.php?jsonMode=force&path=$1 last;

        if ($cookie_umicms_session) {
          error_page 412 = @dynamic;
          return 412;
        }

        if ($request_method = 'POST') {
          error_page 412 = @dynamic;
          return 412;
        }

        index index.php;
        try_files $uri @dynamic;
    }

    location ~* \.js$ {
        rewrite ^\/(udata|upage|uobject|ufs|usel|ulang|utype|umess|uhttp):?(\/\/)?(.*)? /releaseStreams.php?scheme=$1&path=$3 last;
        try_files $uri =404;
    }

    location ~* \.(ico|jpg|jpeg|png|gif|swf|css|ttf)\$ {
        try_files $uri =404;
        access_log off;
        expires 24h;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        include /etc/nginx/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $request_filename;
        fastcgi_intercept_errors on;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
    }

}
server {
    listen 80;
    server_name www.$domain;
    return 301 http://$domain\$request_uri;
    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;
}
EOF
    ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
    nginx -t
    systemctl restart nginx.service
    create_table_if_not_exists
    create_site_record "$username" "$domain"
    echo "The site has been successfully created $domain"
    sleep 3  # Delay for 3 seconds
}

# Nginx configuration for various CMS cs.cart
function configure_cscart() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mWebsite CMS cs.cart\e[0m"
    select_php_version
    echo "Selected PHP version: $php_version"
    configure_php-fpm_d
    create_directories
    # ...
    cat << EOF | tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    add_header Last-Modified \$date_gmt;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Xss-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;

    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;

    charset utf-8;

    set \$root_path /var/www/$username/data/www/$domain;
    root \$root_path;
    disable_symlinks if_not_owner from=\$root_path;
    index index.php index.html index.htm;

    gzip on;
    gzip_disable "msie6";
    gzip_comp_level 6;
    gzip_min_length  1100;
    gzip_buffers 16 8k;
    gzip_proxied any;
    gzip_types text/plain application/xml
    application/javascript
    text/css
    text/js
    text/xml
    application/x-javascript
    text/javascript
    application/json
    application/xml+rss;

    client_max_body_size            100m;
    client_body_buffer_size         128k;
    client_header_timeout           3m;
    client_body_timeout             3m;
    send_timeout                    3m;
    client_header_buffer_size       1k;
    large_client_header_buffers     4 16k;

    error_page 598 = @backend;

    location @backend {
        try_files \$uri \$uri/ /\$2\$3 /\$3 /index.php  =404;

        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        #
        fastcgi_index index.php;
        fastcgi_read_timeout 360;

        fastcgi_param  QUERY_STRING       $query_string;
        fastcgi_param  REQUEST_METHOD     $request_method;
        fastcgi_param  CONTENT_TYPE       $content_type;
        fastcgi_param  CONTENT_LENGTH     $content_length;
        fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
        fastcgi_param  REQUEST_URI        $request_uri;
        fastcgi_param  DOCUMENT_URI       $document_uri;
        fastcgi_param  DOCUMENT_ROOT      $document_root;
        fastcgi_param  SERVER_PROTOCOL    $server_protocol;
        fastcgi_param  HTTPS              $https if_not_empty;
        fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
        fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;
        fastcgi_param  REMOTE_ADDR        $remote_addr;
        fastcgi_param  REMOTE_PORT        $remote_port;
        fastcgi_param  SERVER_ADDR        $server_addr;
        fastcgi_param  SERVER_PORT        $server_port;
        fastcgi_param  SERVER_NAME        $server_name;
        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        fastcgi_param  REDIRECT_STATUS    200;

    }


    location  / {
        index  index.php index.html index.htm;
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ ^/(\w+/)?(\w+/)?api/ {
        rewrite ^/(\w+/)?(\w+/)?api/(.*)\$ /api.php?_d=$3&ajax_custom=1&$args last;
        rewrite_log off;
    }

    location ~ ^/(\w+/)?(\w+/)?var/database/ {
        return 404;
    }

    location ~ ^/(\w+/)?(\w+/)?var/backups/ {
        return 404;
    }

    location ~ ^/(\w+/)?(\w+/)?var/restore/ {
        return 404;
    }

    location ~ ^/(\w+/)?(\w+/)?var/themes_repository/ {
        allow all;
        location ~* \.(tpl|php.?)\$ {
            return 404;
        }
    }

    location ~ ^/(\w+/)?(\w+/)?var/ {
        return 404;
        location ~* /(\w+/)?(\w+/)?(.+\.(js|css|png|jpe?g|gz|yml|xml|svg))\$ {
            try_files \$uri \$uri/ /\$2\$3 /\$3 /index.php?\$args;
            allow all;
            access_log off;
            expires 1M;
            add_header Cache-Control public;
            add_header Access-Control-Allow-Origin *;
        }
    }

    location ~ ^/(\w+/)?(\w+/)?app/payments/ {
        return 404;
        location ~ \.php\$ {
            return 598;
        }
    }

    location ~ ^/(\w+/)?(\w+/)?app/addons/rus_exim_1c/ {
        return 404;
        location ~ \.php\$ {
            return 598;
        }
    }

    location ~ ^/(\w+/)?(\w+/)?app/ {
        return 404;
    }

    location ~ ^/(favicon|apple-touch-icon|homescreen-|firefox-icon-|coast-icon-|mstile-).*\.(png|ico)\$  {
        access_log off;
        try_files $uri =404;
        expires max;
        add_header Access-Control-Allow-Origin *;
        add_header Cache-Control public;
    }

    location ~* /(\w+/)?(\w+/)?(.+\.(jpe?g|jpg|webp|ico|gif|png|css|js|pdf|txt|tar|woff|woff2|svg|ttf|eot|csv|zip|xml|yml))\$ {
        access_log off;
        try_files \$uri \$uri/ /\$2\$3 /\$3 /index.php?\$args;
        expires max;
        add_header Access-Control-Allow-Origin *;
        add_header Cache-Control public;
    }

    location ~ ^/(\w+/)?(\w+/)?design/ {
        allow all;
        location ~* \.(tpl|php.?)\$ {
            return 404;
        }
    }

    location ~ ^/(\w+/)?(\w+/)?images/ {
        allow all;
        location ~* \.(php.?)\$ {
            return 404;
        }
    }

    location ~ ^/(\w+/)?(\w+/)?js/ {
        allow all;
        location ~* \.(php.?)\$ {
            return 404;
        }
    }

    location ~ ^/(\w+/)?(\w+/)?init.php {
        return 404;
    }

    location ~* \.(tpl.?)\$ {
        return 404;
    }

    location ~ /\.(ht|git) {
        return 404;
    }

    location ~* \.php\$ {
        return 598 ;
    }
}
server {
    listen 80;
    server_name www.$domain;
    return 301 http://$domain\$request_uri;
    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;
}
EOF
    ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
    nginx -t
    systemctl restart nginx.service
    create_table_if_not_exists
    create_site_record "$username" "$domain"
    echo "The site has been successfully created $domain"
    sleep 3  # Delay for 3 seconds
}

# Nginx configuration for various Other CMS
function configure_other() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mWebsite Other CMS\e[0m"
    select_php_version
    echo "Selected PHP version: $php_version"
    configure_php-fpm_d
    create_directories
    # ...
    cat << EOF | tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    add_header Last-Modified \$date_gmt;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Xss-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;

    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;

    charset off;
    gzip on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/css text/xml application/javascript text/plain application/json image/svg+xml image/x-icon;
    gzip_comp_level 6;

    set \$root_path /var/www/$username/data/www/$domain;
    root \$root_path;
    disable_symlinks if_not_owner from=\$root_path;

    location / {
        index index.php index.html;
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location ~ \.php\$ {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
     }


    location ~* ^.+\.(jpg|jpeg|gif|png|svg|js|css|mp3|ogg|mpeg|avi|zip|gz|bz2|rar|swf|ico|7z|doc|docx|map|ogg|otf|pdf|tff|tif|txt|wav|webp|woff|woff2|xls|xlsx|xml)\$ {
        try_files \$uri \$uri/ /index.php?\$args;
        expires 30d;
    }

    location @fallback {
        fastcgi_pass unix:/var/opt/remi/php$php_version/run/php-fpm/$domain.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }
}
server {
    listen 80;
    server_name www.$domain;
    return 301 http://$domain\$request_uri;
    access_log /var/www/$username/data/logs/$domain-access.log;
    error_log /var/www/$username/data/logs/$domain-error.log;
}
EOF
    ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
    nginx -t
    systemctl restart nginx.service
    create_table_if_not_exists
    create_site_record "$username" "$domain"
    sleep 4  # Delay for 3 seconds
    echo "The site has been successfully created $domain"
}

function return_to_main_menu() {
    echo "Returning to the main menu"
    return
}

function create_site() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > WEB Server > \e[1mCreate site\e[0m"

    while true; do
        # Display a list of users with UID >= 1000
        echo "Select a user:"
        mapfile -t users < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)

        # Check if there are any users
        if [[ ${#users[@]} -eq 0 ]]; then
            echo -e "\e[31mNo users found, please add at least one user.\e[0m"
            create_user  # Prompt to create a new user
            # Refresh the list of users after creating a new user
            mapfile -t users < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
            # Check again if users are added
            if [[ ${#users[@]} -eq 0 ]]; then
                echo -e "\e[31mFailed to create a user. Returning to main menu.\e[0m"
                return_to_main_menu
                return
            fi
        fi

        declare -A user_sites  # Associative array to store user sites

        # Output list of sites from the database
        echo "List of added sites:"
        # Get sites information from the database
        sites_info=$(sqlite3 /root/database.db "SELECT name, domain FROM sites;")

        if [ -n "$sites_info" ]; then
            # Parse sites_info and populate the user_sites array
            while IFS='|' read -r username domain; do
                if [[ -n ${user_sites["$username"]} ]]; then
                    user_sites["$username"]+=" $domain"
                else
                    user_sites["$username"]="$domain"
                fi
            done <<< "$sites_info"

            # Display user sites
            for username in "${!user_sites[@]}"; do
                echo "User: $username Sites: ${user_sites["$username"]}"
            done
        else
            echo "No sites added yet."
        fi

        #echo "0) Exit"
        echo "1) Create new user"
        for i in "${!users[@]}"; do
            echo "$((i + 2))) ${users[$i]}"
        done
        echo "0) Exit"

        PS3="Enter numbers from 0 to $((${#users[@]} + 1)): "
        read -p "$PS3" choice

        if [[ $choice -eq 0 ]]; then
            return_to_main_menu
            return
        elif [[ $choice -eq 1 ]]; then
            create_user
            # Refresh the list of users after creating a new user
            mapfile -t users < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
            if [[ ${#users[@]} -eq 0 ]]; then
                echo -e "\e[31mFailed to create a user. Returning to main menu.\e[0m"
                return_to_main_menu
                return
            fi
            continue
        elif ((choice > 1 && choice <= ${#users[@]} + 1)); then
            username="${users[$((choice - 2))]}"
            break  # Break out of the while loop
        else
            echo "Invalid choice. Please try again."
        fi
    done

    while true; do
        # Website domain input
        if ! domain=$(prompt_for_input "Enter the site domain (domain.ru): " "Press 'q' to cancel." '^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$'); then
            return_to_main_menu
            return  # Ensure we return to the main menu if the domain input is cancelled
        fi
        # Check if directory exists
        if [ -d "/var/www/$username/data/www/$domain" ]; then
            echo "Directory /var/www/$username/data/www/$domain already exists. Please choose another name."
        else
            mkdir -p "/var/www/$username/data/www/$domain"
            chown $username:$username -R "/var/www/$username/data/www/$domain"
            break
        fi
    done

    CMS=("WordPress" "1C-Bitrix" "Joomla" "MODX Revolution" "OpenCart" "Drupal" "DataLife Engine" "Webasyst CMS (Shop-Script)" "UMI.CMS" "cs.cart" "Other CMS")
    for ((i=0; i<${#CMS[@]}; i++)); do
        echo "$(($i+1))) ${CMS[$i]}"
    done
    read -r -p "Select CMS enter a number from 1 to 11: " cms_choice
    case $cms_choice in
        1) configure_wordpress ;;
        2) configure_bitrix ;;
        3) configure_joomla ;;
        4) configure_modx ;;
        5) configure_opencart ;;
        6) configure_drupal ;;
        7) configure_datalife ;;
        8) configure_shopscript ;;
        9) configure_umi ;;
        10) configure_cscart ;;
        11) configure_other ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
    # Return to the main menu
    return_to_main_menu
}


function check_user_existence() {
    local username="$1"
    if id -u "$username" &>/dev/null; then
        return 0  # User exists
    else
        return 1  # User does not exist
    fi
}

function create_user() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Users > \e[1mCreate user\e[0m"
    echo -e "List of existing users:\n"
    awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd
    echo -e "\n"
    echo -e "* Press 'q' to cancel."
    username=""
    if ! username=$(prompt_for_input "Enter the new user's name: " "" '^[a-z0-9]+$'); then
        return  # Возвращаемся к предыдущему меню
    fi

    # Check user input
    if [[ $username == "exit" || $username == "q" ]]; then
        echo -e "Returning to the previous menu..."
        return
    fi

    if [[ $username == "root" ]]; then
        echo -e "\e[31mUsername 'root' is not allowed.\e"
        return
    fi

    if [[ $username == "q" ]]; then
        echo -e "\e[31mUsername 'root' is not allowed.\e"
        return
    fi

    if id -u "$username" &>/dev/null && [[ $(id -u "$username") -lt 1000 ]]; then
        echo -e  "\e[32mСистемный пользователь '$username' не может быть создан.\e[0m"
        return
    fi

    check_user_existence "$username"
    if [ $? -eq 0 ]; then
        echo -e "\e[31mBenutzer mit dem Namen '$username' existiert bereits.\e[0m"
        return
    fi

    useradd -m -s /bin/bash -d /var/www/$username $username
    mkdir -p /var/www/$username/data/logs
    chown -R $username:$username /var/www/$username
    chmod -R 755 /var/www/$username
    # Check if there is data in the database
    number_of_sites=$(sqlite3 /root/database.db "SELECT count(*) FROM sqlite_master WHERE type='table';")
    echo -e "Number of sites: $number_of_sites"

    if [ "$number_of_sites" -eq 0 ]; then
        create_site
    fi
}

function delete_user() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Users > \e[1mDelete user\e[0m"

    # Get a list of users with UID >= 1000
    mapfile -t users < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)

    # Check if there are any users
    if [[ ${#users[@]} -eq 0 ]]; then
        echo -e "\e[31mPlease add at least one user.\e[0m"
        return
    fi

    # Display the users in a numbered list
    echo "List of existing users:"
    for i in "${!users[@]}"; do
        echo "$((i+1))) ${users[$i]}"
    done

    echo -e "\n"
    echo -e "Press 'q' to return."

    local choice
    read -p "Enter the number of the user to delete: " choice

    # Check if the choice is a number within the valid range
    if [[ $choice =~ ^[1-9][0-9]*$ ]] && [ $choice -ge 1 ] && [ $choice -le ${#users[@]} ]; then
        username="${users[$((choice-1))]}"
    else
        echo "Invalid choice. Please try again."
        return
    fi

    if [[ $username == "root" ]]; then
        echo -e "\e[31mThe username 'root' is not allowed.\e[0m"
        exit 0
    fi

    # Find all .conf files in /etc/nginx/sites-available that contain the string "root /var/www/$username"
    config_files=$(grep -lR "root /var/www/$username" /etc/nginx/sites-available/*.conf)

    # If such files are found, delete them and the corresponding symbolic links
    if [ ! -z "$config_files" ]; then
        echo "Deleting configuration files and symbolic links associated with user $username:"
        for file in $config_files; do
            # Get the filename without path and extension
            filename=$(basename -- "$file")
            filename="${filename%.*}"

            # Delete the symbolic link
            if [ -L "/etc/nginx/sites-enabled/$filename" ]; then
                echo "Deleting symbolic link /etc/nginx/sites-enabled/$filename"
                rm "/etc/nginx/sites-enabled/$filename"
            fi

            # Delete the configuration file
            echo "Deleting $file"
            rm $file
        done
    fi

    # Delete PHP-FPM configuration files and sockets for the user
    config_files=$(grep -lR "user = $username" /etc/opt/remi/php*/php-fpm.d/*.conf)
    for config_file in $config_files; do
        echo "Deleting PHP-FPM configuration file: $config_file"
        rm "$config_file"
    done

    sock_files=$(grep -lR "user = $username" /etc/opt/remi/php*/php-fpm.d/*.conf | xargs grep -l "listen =")
    for sock_file in $sock_files; do
        sock_path=$(grep -E "listen\s*=\s*.+\.sock" "$sock_file" | sed -E 's/.*listen\s*=\s*(.+\.sock).*/\1/')
        echo "Deleting PHP-FPM socket file: $sock_path"
        rm "$sock_path"
    done
    systemctl restart "php${php_version}-php-fpm.service"
    systemctl restart nginx.service
    # Delete the user
    if id -u "$username" &>/dev/null; then
        userdel -r $username
        echo -e "Deleting user '$username'"  # Message about successful deletion

        # Delete the user's records from the database
        local sql_query="DELETE FROM sites WHERE name = '$username';"
        sqlite3 /root/database.db "$sql_query"
        if [ $? -eq 0 ]; then
            echo -e "\e[32mUser's records deleted from database successfully\e[0m"
        else
            echo -e "\e[31mFailed to delete user's records from database\e[0m"
        fi
    else
        echo "\e[31mUser '$username' not found.\e[0m"
    fi
}

# Function to delete a site
function delete_site() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > WEB Server > \e[1mDelete site\e[0m"

    # Output list of sites from the database
    echo "List of added sites:"
    sites_info=$(sqlite3 /root/database.db "SELECT name, domain FROM sites;")
    current_user=""
    declare -A user_sites  # Associative array to store user sites
    while IFS='|' read -r username domain; do
        if [[ $username != "$current_user" ]]; then
            if [[ -n $current_user ]]; then
                # Output the sites for the current user
                echo "User: $current_user Sites: ${user_sites[$current_user]}"
            fi
            current_user="$username"
            user_sites["$username"]=""  # Initialize user sites array
        fi
        # Append site to user's sites array
        if [[ -n $username ]]; then
            user_sites["$username"]+=" $domain"
        fi
    done <<< "$sites_info"
    if [[ -n $current_user ]]; then
        # Output the sites for the last user
        echo "User: $current_user Sites: ${user_sites[$current_user]}"
    fi

    # Check if there are any sites
    if [[ ${#user_sites[@]} -eq 0 ]]; then
        echo -e "\e[31mNo sites found, please add at least one site.\e[0m"
        return
    fi

    # Display the users and prompt for user selection
    users=("${!user_sites[@]}")
    while true; do
        echo "Available users:"
        for i in "${!users[@]}"; do
            echo "$((i+1))) ${users[i]}"
        done
        echo "0) Exit"
        read -p "Enter numbers from 0 to ${#users[@]}: " choice
        if [[ $choice == "0" ]]; then
            echo "Exiting..."
            return
        elif ((choice > 0 && choice <= ${#users[@]})); then
            username="${users[choice-1]}"
            break
        else
            echo -e "\e[31mInvalid choice. Please try again.\e[0m"
        fi
    done

    # Display the user's sites and prompt for site selection
    sites="${user_sites[$username]}"
    if [[ -z $sites ]]; then
        echo -e "\e[31mNo sites found for user $username.\e[0m"
        return
    fi

    sites_array=($sites)
    while true; do
        echo "Sites for user $username:"
        for i in "${!sites_array[@]}"; do
            echo "$((i+1))) ${sites_array[i]}"
        done
        echo "0) Exit"
        read -p "Enter numbers from 0 to ${#sites_array[@]}: " choice
        if [[ $choice == "0" ]]; then
            echo "Exiting..."
            return
        elif ((choice > 0 && choice <= ${#sites_array[@]})); then
            site="${sites_array[choice-1]}"
            break
        else
            echo -e "\e[31mInvalid choice. Please try again.\e[0m"
        fi
    done

    # Get the ID of the selected site
    local site_id=$(sqlite3 /root/database.db "SELECT id FROM sites WHERE name='$username' AND domain='$site';")

    # Delete the site from the database
    sqlite3 /root/database.db "DELETE FROM sites WHERE id = $site_id;"

    # Delete the site's files and Nginx configuration
    rm -rf "/var/www/$username/data/www/$site"
    rm "/etc/nginx/sites-available/$site.conf"
    rm "/etc/nginx/sites-enabled/$site.conf"
    rm "/var/opt/remi/php${php_version}/run/php-fpm/${site}.sock"
    rm "/etc/opt/remi/php${php_version}/php-fpm.d/${site}.conf"
    systemctl restart "php${php_version}-php-fpm.service"
    systemctl restart nginx.service
    echo "Site $site deleted successfully."
}

# Check for data in the database
number_of_sites=$(sqlite3 /root/database.db "SELECT count(*) FROM sqlite_master WHERE type='table';")
#echo -e "Number of sites:"."$number_of_sites"

if [ "$number_of_sites" -eq 0 ]; then
    create_user
fi

# WEB SERVER
function lemp_server() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > \e[1mWEB Server\e[0m"
        echo "Select an action:"
        echo "1) Create Site"
        echo "2) Delete Site"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 2: " REPLY

        case $REPLY in
            1)
                echo "You chose Create Site"
                create_site # Call your create_site function here
                ;;
            2)
                echo "You chose Delete Site"
                delete_site # Call your delete_site function here
                ;;
            0)
                echo "Exiting..."
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 2."
                ;;
        esac
    done
}

function add_mariadb_repo() {
    while true; do
    clear  # Clear the screen
    display_header
    echo -e "\e[1mMariaDB Repositories\e[0m"
        # Check if MariaDB repository is already added
        if yum repolist | grep MariaDB &> /dev/null; then
            echo -e "\e[31mMariaDB repository is already added.\e[0m"
            read -p "Remove the old repository and add a new one? (y/n): " confirm
            if [[ "$confirm" == "n" ]]; then
                echo -e "\e[32mReturning to the previous menu...\e[0m"
                return
            else
                echo -e "\e[32mRemoving old MariaDB repository...\e[0m"
                rm -f /etc/yum.repos.d/mariadb.repo.old*
            fi
        fi

        echo "Select the version of MariaDB to add to the repository:"
        echo "1) MariaDB-11.4"
        echo "2) MariaDB-11.2"
        echo "3) MariaDB-11.1"
        echo "4) MariaDB-11.0"
        echo "5) MariaDB-10.11"
        echo "6) MariaDB-10.10"
        echo "7) MariaDB-10.6"
        echo "8) MariaDB-10.5"
        echo "9) MariaDB-10.4"
        read -p "Enter the version number (or 'q' to exit): " version

        case $version in
            1)
                repo_version="mariadb-11.4"
                ;;
            2)
                repo_version="mariadb-11.2"
                ;;
            3)
                repo_version="mariadb-11.1"
                ;;
            4)
                repo_version="mariadb-11.0"
                ;;
            5)
                repo_version="mariadb-10.11"
                ;;
            6)
                repo_version="mariadb-10.10"
                ;;
            7)
                repo_version="mariadb-10.6"
                ;;
            8)
                repo_version="mariadb-10.5"
                ;;
            9)
                repo_version="mariadb-10.4"
                ;;
            q)
                echo -e "\e[32mReturning to the previous menu...\e[0m"
                return
                ;;
            *)
                echo -e "\e[31mInvalid version choice.\e[0m"
                continue
                ;;
        esac

        # Adding the MariaDB repository using curl
        if ! curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash -s -- --mariadb-server-version="$repo_version"; then
            echo -e "\e[31mFailed to add MariaDB repository $repo_version. Returning to the previous menu...\e[0m"
            return
        fi

        echo -e "\e[32mMariaDB repository $repo_version added.\e[0m"
    done
}

function install_mariadb() {
    clear  # Clear the screen
    display_header
    echo -e "\e[1mInstall MariaDB\e[0m"
    # Check if MariaDB is already installed
    if mariadb --version &> /dev/null; then
        echo -e "\e[31mMariaDB is already installed. Returning to the previous menu...\e[0m"
        return
    fi

    # Check for the presence of the MariaDB repository
    if ! yum repolist | grep MariaDB &> /dev/null; then
        echo -e "\e[31mMariaDB repository not found. Adding repository...\e[0m"
        add_mariadb_repo
    fi

    # Request confirmation for installing MariaDB
    read -p "Are you sure you want to install MariaDB? (y/n or 'q' to exit): " confirm
    if [[ "$confirm" == "q" ]]; then
        echo -e "\e[32mReturning to the previous menu...\e[0m"
        return
    fi
    if [[ "$confirm" == "y" ]]; then
        echo -e "\e[32mInstalling MariaDB...\e[0m"
        dnf install MariaDB-server -y
        echo -e "\e[32mEnabling MariaDB to start after OS boot\e[0m"
        /usr/bin/systemctl enable mariadb
        echo -e "\e[32mStarting MariaDB\e[0m"
        /usr/bin/systemctl start mariadb
    fi
}

function remove_mariadb() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Applications > Remove Packages > \e[1mUninstall MariaDB\e[0m"
    # Check if MariaDB is installed
    if ! mariadb --version &> /dev/null; then
        echo -e "\e[31mMariaDB has already been removed. Returning to the previous menu...\e[0m"
        return
    fi

    # Prompt for confirmation to remove MariaDB
    read -p "Are you sure you want to remove MariaDB? (y/n or 'q' to quit): " confirm
    if [[ "$confirm" == "q" ]]; then
        echo -e "\e[32mReturning to the previous menu...\e[0m"
        return
    fi
    if [[ "$confirm" == "y" ]]; then
        echo -e "\e[32mRemoving MariaDB...\e[0m"
        dnf remove MariaDB-server -y
    fi
}

function create_db_and_user() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > MariaDB Server > \e[1mCreate a MariaDB user and database\e[0m"
    # Display information about databases and users
    echo "List of databases:"
    /usr/bin/mariadb -u root -e "SHOW DATABASES;"
    echo "List of users:"
    /usr/bin/mariadb -u root -e "SELECT User, Host FROM mysql.user;"

    # Prompt for database name
    while true; do
        read -p "Enter the database name (or 'q' to quit): " DB_NAME
        if [ "$DB_NAME" = "q" ]; then
            echo -e "\e[32mReturning to the previous menu...\e[0m"
            return
        fi

        # Check if the database name is a system database
        if [[ "$DB_NAME" =~ ^(mysql|information_schema|performance_schema|sys|test)\$ ]]; then
            echo -e "\e[31mCannot create a system database.\e[0m"
            continue
        fi

        # Check for invalid characters in the database name
        if [[ "$DB_NAME" =~ [^a-zA-Z0-9_] ]]; then
            echo -e "\e[31mInvalid characters in the database name.\e[0m"
            continue
        fi

        # Check if the database already exists
        DB_EXISTS=$(/usr/bin/mariadb -u root -e "SHOW DATABASES LIKE '${DB_NAME}';" | grep -w "${DB_NAME}")
        if [ "$DB_EXISTS" = "$DB_NAME" ]; then
            echo -e "\e[31mDatabase '${DB_NAME}' already exists. Try another name.\e[0m"
            continue
        else
            break
        fi
    done

    # Prompt for username
    while true; do
        read -p "Enter the username (or 'q' to quit): " DB_USER
        if [ "$DB_USER" = "q" ]; then
            echo -e "\e[32mReturning to the previous menu...\e[0m"
            return
        fi

        # Check if the username is a system user
        if [[ "$DB_USER" =~ ^(mariadb.sys|mysql|root)\$ ]]; then
            echo -e "\e[31mCannot create a system user. Try another name.\e[0m"
            continue
        fi

        # Check for invalid characters in the username
        if [[ "$DB_USER" =~ [^a-zA-Z0-9_] ]]; then
            echo -e "\e[31mInvalid characters in the username. Try another name.\e[0m"
            continue
        fi

        # Check if the user already exists
        USER_EXISTS=$(/usr/bin/mariadb -u root -e "SELECT User FROM mysql.user WHERE User = '${DB_USER}';" | grep "${DB_USER}")
        if [ "$USER_EXISTS" = "$DB_USER" ]; then
            echo -e "\e[31mUser '${DB_USER}' already exists. Try another name.\e[0m"
            continue
        else
            break
        fi
    done

    # Prompt for password
    read -s -p "Enter the password (or 'q' to quit): " DB_PASSWORD
    echo
    if [ "$DB_PASSWORD" = "q" ]; then
        echo -e "\e[32mReturning to the previous menu...\e[0m"
        return
    fi

    # Prompt for database charset
    read -p "Enter the database charset (default is 'utf8mb4', 'q' to cancel): " DB_CHARSET
    if [ "$DB_CHARSET" = "q" ]; then
        echo -e "\e[32mReturning to the previous menu...\e[0m"
        return
    fi

    # Default charset
    DB_CHARSET=${DB_CHARSET:-utf8mb4}

    # Create the database with the specified charset
    /usr/bin/mariadb -u root -e "CREATE DATABASE ${DB_NAME} CHARACTER SET ${DB_CHARSET};"

    # Create the user
    /usr/bin/mariadb -u root -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"

    # Grant all privileges to the user on the database
    /usr/bin/mariadb -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"

    # Apply the changes
    /usr/bin/mariadb -u root -e "FLUSH PRIVILEGES;"

    echo -e "\e[32mDatabase created. User added.\e[0m"

    # Display information about databases and users
    echo "List of databases:"
    /usr/bin/mariadb -u root -e "SHOW DATABASES;"
    echo "List of users:"
    /usr/bin/mariadb -u root -e "SELECT User, Host FROM mysql.user;"
}
function status_mariadb() {
    echo -e "\e[32mGetting status of MariaDB...\e[0m"
    status=$(/usr/bin/systemctl status mariadb | grep Active)
    if [[ $status == *"active (running)"* ]]; then
        echo -e "\e[32mService is running.\e[0m"
    elif [[ $status == *"inactive (dead)"* ]]; then
        echo -e "\e[31mService is stopped.\e[0m"
    else
        echo -e "\e[33mService status unknown.\e[0m"
    fi

    while true; do
        read -n1 -r -p "Press 'q' to return to the previous menu..." key
        if [ "$key" = 'q' ]; then
            echo -e "\e[32mReturning to the previous menu...\e[0m"
            return
        fi
    done
}
function mariadb_services() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Services > \e[1mMariaDB services\e[0m"
        echo "Select an action:"
        echo "1) Start MariaDB"
        echo "2) Stop MariaDB"
        echo "3) Restart MariaDB"
        echo "4) Status of MariaDB"
        echo "5) Add to autostart"
        echo "6) Remove from autostart"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 6: " action

        case $action in
            1)
                status=$(/usr/bin/systemctl is-active mariadb)
                if [[ $status == "active" ]]; then
                    echo -e "\e[32mService is already running.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStarting MariaDB...\e[0m"
                /usr/bin/systemctl start mariadb
                ;;
            2)
                status=$(/usr/bin/systemctl is-active mariadb)
                if [[ $status == "inactive" ]]; then
                    echo -e "\e[31mService is already stopped.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStopping MariaDB...\e[0m"
                /usr/bin/systemctl stop mariadb
                ;;
            3)
                echo -e "\e[32mRestarting MariaDB...\e[0m"
                /usr/bin/systemctl restart mariadb
                ;;
            4)
                status_mariadb
                ;;
            5)
                enabled=$(/usr/bin/systemctl is-enabled mariadb)
                if [[ $enabled == "enabled" ]]; then
                    echo -e "\e[32mService is already added to autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mAdding MariaDB to autostart...\e[0m"
                /usr/bin/systemctl enable mariadb
                ;;
            6)
                enabled=$(/usr/bin/systemctl is-enabled mariadb)
                if [[ $enabled == "disabled" ]]; then
                    echo -e "\e[31mService is already removed from autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mRemoving MariaDB from autostart...\e[0m"
                /usr/bin/systemctl disable mariadb
                ;;
            0)
                echo -e "\e[32mReturning to the previous menu...\e[0m"
                return
                ;;
            *)
                echo -e "\e[31mInvalid action choice.\e[0m"
                continue
                ;;
        esac
    done
}

function remove_db_and_user() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > MariaDB Server > \e[1mDelete user and MariaDB database\e[0m"
    # Getting the list of databases and users
    DB_USER_LIST=$(/usr/bin/mariadb -u root -e "SELECT Db, User FROM mysql.db WHERE User NOT IN ('mariadb.sys', 'mysql', 'root', 'User', 'PUBLIC') AND Db NOT LIKE 'Db' AND Db NOT LIKE 'test\\\\_%';")

    # Check if there is anything to remove
    if [ -z "$DB_USER_LIST" ]; then
        echo -e "\e[31mThere are no databases or users to remove.\e[0m"
        return
    fi

    # Displaying the list of databases and users
    echo -e "\e[32mExisting databases and users:\e[0m"
    echo "$DB_USER_LIST" | awk '{print NR ". database " $1 " belonging to user " $2}'

    # Asking for the number to remove
    read -p "Enter the number to remove (or 'q' to exit): " NUMBER

    # Check if the user wants to exit
    if [ "$NUMBER" = "q" ]; then
        echo -e "\e[32mReturning to the previous menu...\e[0m"
        return
    fi

    # Check if the input is a number
    if ! [[ "$NUMBER" =~ ^[0-9]+$ ]]; then
        echo -e "\e[31mInput must be a number.\e[0m"
        return
    fi

    # Getting the name of the database and user to remove
    DB_NAME=$(echo "$DB_USER_LIST" | awk 'NR == '$NUMBER' {print $1}')
    DB_USER=$(echo "$DB_USER_LIST" | awk 'NR == '$NUMBER' {print $2}')

    # Removing the database
    if ! /usr/bin/mariadb -u root -e "DROP DATABASE ${DB_NAME};"; then
        echo -e "\e[31mFailed to remove the database.\e[0m"
        sleep 3  # Delay for 3 seconds
        return
    fi

    # Removing the user
    if ! /usr/bin/mariadb -u root -e "DROP USER '${DB_USER}'@'localhost';"; then
        echo "\e[31mFailed to remove the user.\e[0m"
        sleep 3  # Delay for 3 seconds
        return
    fi

    echo -e "\e[32mDatabase and user removed.\e[0m"
    sleep 3  # Delay for 3 seconds
}

function upload_mysql_dump() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > MariaDB Server > \e[1mLoad dump into database\e[0m"
    # Display information about databases and users
    echo "List of databases:"
    /usr/bin/mariadb -u root -e "SHOW DATABASES;"
    echo "List of users:"
    /usr/bin/mariadb -u root -e "SELECT User, Host FROM mysql.user;"
    echo "Enter the details for uploading the MySQL dump:"
    read -p "Server (default localhost, 'q' to cancel): " server
    if [[ "$server" == "q" ]]; then
        echo -e "\e[31mOperation cancelled.\e[0m"
        return
    fi
    read -p "Username (default root, 'q' to cancel): " user
    if [[ "$user" == "q" ]]; then
        echo -p "\e[31mOperation cancelled.\e[0m"
        return
    fi
    read -s -p "Password (press Enter if none, 'q' to cancel): " password
    echo ""
    if [[ "$password" == "q" ]]; then
        echo -e "\e[31mOperation cancelled.\e[0m"
        return
    fi
    read -p "Database (mandatory, 'q' to cancel): " database
    if [[ "$database" == "q" ]]; then
        echo -e "\e[31mOperation cancelled.\e[0m"
        return
    fi
    read -p "Path to dump file (default /root/mysqldump.sql, 'q' to cancel): " dump_file
    if [[ "$dump_file" == "q" ]]; then
        echo -e "\e[31mOperation cancelled.\e[0m"
        return
    fi

    # Default values
    server=${server:-localhost}
    user=${user:-root}
    dump_file=${dump_file:-/root/mysqldump.sql}

    # Escaping user input
    server=$(printf '%q' "$server")
    user=$(printf '%q' "$user")
    password=$(printf '%q' "$password")
    database=$(printf '%q' "$database")
    dump_file=$(printf '%q' "$dump_file")

    if [[ ! -f $dump_file ]]; then
        echo "Dump file '$dump_file' not found."
        return 1
    fi

    # Checking for the existence of the database on the server
    echo -e "\e[32mChecking for the existence of database '$database' on server '$server'...\e[0m"
    if [[ -z $password ]]; then
        db_exists=$(/usr/bin/mariadb -h $server -u $user -e "SHOW DATABASES LIKE '$database';" | grep "$database")
    else
        db_exists=$(/usr/bin/mariadb -h $server -u $user -p$password -e "SHOW DATABASES LIKE '$database';" | grep "$database")
    fi

    if [[ -z $db_exists ]]; then
        echo -e "\e[31mDatabase '$database' not found on server '$server'.\e[0m"
        return 1
    fi

    echo -e "\e[32mUploading dump '$dump_file' to server '$server' into database '$database'...\e[0m"

    if [[ -z $password ]]; then
        /usr/bin/mariadb -h $server -u $user $database < $dump_file
    else
        /usr/bin/mariadb -h $server -u $user -p$password $database < $dump_file
    fi

    if [[ $? -eq 0 ]]; then
        echo -e "\e[32mDump successfully uploaded.\e[0m"
        sleep 3  # Delay for 3 seconds
    else
        echo -e "\e[31mAn error occurred while uploading the dump.\e[0m"
        sleep 3  # Delay for 3 seconds
    fi
}
function create_mysql_dump() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > MariaDB Server > \e[1mCreate a database dump\e[0m"
    # Display information about databases and users
    echo "List of databases:"
    /usr/bin/mariadb -u root -e "SHOW DATABASES;"
    echo "List of users:"
    /usr/bin/mariadb -u root -e "SELECT User, Host FROM mysql.user;"
    echo "Enter the details for creating the MySQL dump:"
    read -p "Server (default localhost, 'q' to cancel): " server
    if [[ "$server" == "q" ]]; then
        echo -e "\e[31mOperation cancelled.\e[0m"
        return
    fi
    read -p "Username (default root, 'q' to cancel): " user
    if [[ "$user" == "q" ]]; then
	echo -e "\e[31mOperation cancelled.\e[0m"
        return
    fi
    read -s -p "Password (press Enter if none, 'q' to cancel): " password
    echo ""
    if [[ "$password" == "q" ]]; then
	echo -e "\e[31mOperation cancelled.\e[0m"
        return
    fi
    read -p "Database (mandatory, 'q' to cancel): " database
    if [[ "$database" == "q" ]]; then
	echo -e "\e[31mOperation cancelled.\e[0m"
        return
    fi
    read -p "Path to dump file (default /root/mysqldump.sql, 'q' to cancel): " dump_file
    if [[ "$dump_file" == "q" ]]; then
	echo -e "\e[31mOperation cancelled.\e[0m"
        return
    fi

    # Default values
    server=${server:-localhost}
    user=${user:-root}
    dump_file=${dump_file:-/root/mysqldump.sql}

    # Escaping user input
    server=$(printf '%q' "$server")
    user=$(printf '%q' "$user")
    password=$(printf '%q' "$password")
    database=$(printf '%q' "$database")
    dump_file=$(printf '%q' "$dump_file")

    # Checking for the existence of the database on the server
    echo -e "\e[32mChecking for the existence of database '$database' on server '$server'...\e[0m"
    if [[ -z $password ]]; then
        db_exists=$(/usr/bin/mariadb -h $server -u $user -e "SHOW DATABASES LIKE '$database';" | grep "$database")
    else
        db_exists=$(/usr/bin/mariadb -h $server -u $user -p$password -e "SHOW DATABASES LIKE '$database';" | grep "$database")
    fi

    if [[ -z $db_exists ]]; then
        echo -e "\e[31mDatabase '$database' not found on server '$server'.\e[0m"
        return 1
    fi

    echo -e "\e[32mCreating dump of database '$database' on server '$server' into file '$dump_file'...\e[0m"

    if [[ -z $password ]]; then
        /usr/bin/mariadb-dump -h $server -u $user $database > $dump_file
    else
        /usr/bin/mariadb-dump -h $server -u $user -p$password $database > $dump_file
    fi

    if [[ $? -eq 0 ]]; then
        echo -e "\e[32mDump successfully created.\e[0m"
        sleep 3  # Delay for 3 seconds
    else
        echo -e "\e[32mAn error occurred while creating the dump.\e[0m"
        sleep 3  # Delay for 3 seconds
    fi
}

# MySQL SERVER
function mysql_server() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > \e[1mMariaDB Server\e[0m"
        echo "Select an action:"
        echo "1) Create a MariaDB user and database"
        echo "2) Delete user and MariaDB database"
        echo "3) Load dump into database"
        echo "4) Create a database dump"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 4: " REPLY

        case $REPLY in
            1)
                echo "You chose Create a MariaDB user and database"
                create_db_and_user # Call your create_db_and_user function here
                ;;
            2)
                echo "You chose Delete user and MariaDB database"
                remove_db_and_user # Call your remove_db_and_user function here
                ;;
            3)
                echo "You chose Load dump into database"
                upload_mysql_dump # Call your upload_mysql_dump function here
                ;;
            4)
                echo "You chose Create a database dump"
                create_mysql_dump # Call your create_mysql_dump function here
                ;;
            0)
                echo "Exiting..."
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 4."
                ;;
        esac
    done
}

# Package removal function
function remove_packages() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Applications > \e[1mRemove Packages\e[0m"
        echo "Select a package to remove:"
        echo "1) MariaDB"
        echo "2) Nginx"
        echo "3) Let's Encrypt"
        echo "4) PHP"
        echo "5) Fail2ban"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 5: " REPLY

        case $REPLY in
            1)
                echo "You chose MariaDB"
                remove_mariadb # Call your remove_mariadb function here
                ;;
            2)
                echo "You chose Nginx"
                remove_nginx # Call your remove_nginx function here
                ;;
            3)
                echo "You chose Let's Encrypt"
                remove_letsencrypt # Call your remove_letsencrypt function here
                ;;
            4)
                echo "You chose PHP"
                remove_php # Call your remove_php function here
                ;;
            5)
                echo "You chose Fail2ban"
                remove_fail2ban # Call your remove_fail2ban function here
                ;;
            0)
                echo "Exiting..."
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 5."
                ;;
        esac
    done
}


function install_php() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Applications > Install Packages > \e[1mInstall PHP packages\e[0m"
        echo "Select a package to install:"
        echo "1) PHP-7.4"
        echo "2) PHP-8.0"
        echo "3) PHP-8.1"
        echo "4) PHP-8.2"
        echo "5) PHP-8.3"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 5: " REPLY
        case $REPLY in
            1)
                echo "You chose PHP-7.4"
                install_php74  # Call your install_php74 function here
                ;;
            2)
                echo "You chose PHP-8.0"
                install_php80  # Call your install_php80 function here
                ;;
            3)
                echo "You chose PHP-8.1"
                install_php81  # Call your install_php81 function here
                ;;
            4)
                echo "You chose PHP-8.2"
                install_php82  # Call your install_php82 function here
                ;;
            5)
                echo "You chose PHP-8.3"
                install_php83  # Call your install_php83 function here
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 5."
                ;;
        esac
    done
}


function remove_php() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Applications > Remove Packages > \e[1mRemove PHP packages\e[0m"
        echo "Select a package to remove:"
        echo "1) PHP-7.4"
        echo "2) PHP-8.0"
        echo "3) PHP-8.1"
        echo "4) PHP-8.2"
        echo "5) PHP-8.3"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 5: " REPLY

        case $REPLY in
            1)
                echo "You chose PHP-7.4"
                remove_php74  # Call your remove_php74 function here
                ;;
            2)
                echo "You chose PHP-8.0"
                remove_php80  # Call your remove_php80 function here
                ;;
            3)
                echo "You chose PHP-8.1"
                remove_php81  # Call your remove_php81 function here
                ;;
            4)
                echo "You chose PHP-8.2"
                remove_php82  # Call your remove_php82 function here
                ;;
            5)
                echo "You chose PHP-8.3"
                remove_php83  # Call your remove_php83 function here
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 5."
                ;;
        esac
    done
}

function parse_iptables() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Security > Firewall (IPTables) > \e[1mView firewall rules\e[0m"
    iptables -L -vn | awk '/dpt:/ {match($0, /dpt:[0-9]+/, arr); split(arr[0],a,":"); print "Port " a[2] "/tcp Open"}'
    #sleep 10

    while true; do
        read -n1 -r -p "Press 'q' to return to the previous menu..." key
        if [ "$key" = 'q' ]; then
            # Вернуться в предыдущее меню
            return
        fi
    done
}

function check_service_status_php_fpm() {
    local service=$1  # Get service name from function parameter
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Services > PHP-FPM Services > \e[1mView $service services status\e[0m"
    echo -e "\e[32mGetting status of $service...\e[0m"
    status=$(/usr/bin/systemctl status $service | grep Active)
    if [[ $status == *"active (running)"* ]] || [[ $status == *"active (exited)"* ]]; then
        echo -e "\e[32mService is running.\e[0m"
        sleep 3
    elif [[ $status == *"inactive (dead)"* ]]; then
        echo -e "\e[31mService is stopped.\e[0m"
        sleep 3
    else
        echo -e "\e[33mService status unknown.\e[0m"
        sleep 3
    fi

    while true; do
        read -n1 -r -p "Press 'q' to return to the previous menu..." key
        if [ "$key" = 'q' ]; then
            # Return to previous menu
            echo -e "\e[32mReturning to the previous menu...\e[0m"
            break
        fi
    done
}


function check_service_status_iptables() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Services > IPTables Services > \e[1mView firewall status\e[0m"
    local services=("iptables" "ip6tables")
    for service in "${services[@]}"; do
        echo -e "\e[32mGetting status of $service...\e[0m"
        status=$(/usr/bin/systemctl status $service | grep Active)
        if [[ $status == *"active (running)"* ]] || [[ $status == *"active (exited)"* ]]; then
            echo -e "\e[32mService is running.\e[0m"
            sleep 3
        elif [[ $status == *"inactive (dead)"* ]]; then
            echo -e "\e[31mService is stopped.\e[0m"
            sleep 3
        else
            echo -e "\e[33mService status unknown.\e[0m"
            sleep 3
        fi
    done

    while true; do
        read -n1 -r -p "Press 'q' to return to the previous menu..." key
        if [ "$key" = 'q' ]; then
            # Вернуться в предыдущее меню
            echo -e "\e[32mReturning to the previous menu...\e[0m"
            break
        fi
    done
}

function check_service_status_nginx() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Services > Nginx Services > \e[1mViewing Nginx Service Status\e[0m"
    local services=("nginx")
    for service in "${services[@]}"; do
        echo -e "\e[32mGetting status of $service...\e[0m"
        status=$(/usr/bin/systemctl status $service | grep Active)
        if [[ $status == *"active (running)"* ]] || [[ $status == *"active (exited)"* ]]; then
            echo -e "\e[32mService is running.\e[0m"
            sleep 3
        elif [[ $status == *"inactive (dead)"* ]]; then
            echo -e "\e[31mService is stopped.\e[0m"
            sleep 3
        else
            echo -e "\e[33mService status unknown.\e[0m"
            sleep 3
        fi
    done

    while true; do
        read -n1 -r -p "Press 'q' to return to the previous menu..." key
        if [ "$key" = 'q' ]; then
            # Вернуться в предыдущее меню
            echo -e "\e[32mReturning to the previous menu...\e[0m"
            break
        fi
    done
}

function check_service_status_fail2ban() {
    clear  # Clear the screen
    display_header
    echo -e "Main menu > Settings > Services > Fail2Ban Services > \e[1mViewing Fail2Ban Service Status\e[0m"
    local services=("fail2ban")
    for service in "${services[@]}"; do
        echo -e "\e[32mGetting status of $service...\e[0m"
        status=$(/usr/bin/systemctl status $service | grep Active)
        if [[ $status == *"active (running)"* ]] || [[ $status == *"active (exited)"* ]]; then
            echo -e "\e[32mService is running.\e[0m"
            sleep 3
        elif [[ $status == *"inactive (dead)"* ]]; then
            echo -e "\e[31mService is stopped.\e[0m"
            sleep 3
        else
            echo -e "\e[33mService status unknown.\e[0m"
            sleep 3
        fi
    done

    while true; do
        read -n1 -r -p "Press 'q' to return to the previous menu..." key
        if [ "$key" = 'q' ]; then
            # Return to the previous menu
            echo -e "\e[32mReturning to the previous menu...\e[0m"
            break
        fi
    done
}


function firewall() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Security > \e[1mFirewall (IPTables)\e[0m"
        echo "Select an action:"
        echo "1) Create default rules"
        echo "2) View firewall rules"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 2: " action

        case $action in
            1)
                create_default_rules
                echo -e "\e[32mCreating Default Rules...\e[0m"
                ;;
            2)
                parse_iptables
                echo -e "\e[32mView IPTables firewall rules...\e[0m"
                ;;
            0)
                echo -e "\e[32mReturning to the previous menu...\e[0m"
                return
                ;;
            *)
                echo -e "\e[31mInvalid action choice.\e[0m"
                continue
                ;;
        esac
    done
}

function fail2ban() {
    clear  # Clear the screen
    display_header_warning
    echo -e "Main menu > Settings > Security > \e[1mFail2ban\e[0m"
    echo "The Fail2ban configuration functionality has not yet been implemented."
    sleep 5  # Delay for 5 seconds
}

function waf() {
    clear  # Clear the screen
    display_header_warning
    echo -e "Main menu > Settings > Security > \e[1mModSecury (WAF)\e[0m"
    echo "The WAF firewall configuration functionality is not yet implemented."
    sleep 5  # Delay for 5 seconds
}

function selinux() {
    clear  # Clear the screen
    display_header_warning
    echo -e "Main menu > Settings > Security > \e[1mSELinux\e[0m"
    echo "The Security-Enhanced Linux (SELinux) configuration functionality has not yet been implemented."
    sleep 5  # Delay for 5 seconds
}

function security() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > \e[1mSecurity\e[0m"
        echo "Select an action:"
        echo "1) Firewall (iptables)"
        echo -e "\e[0;37m2) Fail2ban\e[0m"
        echo -e "\e[0;37m3) ModSecury (WAF)\e[0m"
        echo -e "\e[0;37m4) SELinux\e[0m"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 4: " REPLY

        case $REPLY in
            1)
                echo "The firewall configuration functionality has not yet been implemented."
                firewall  # Call your Firewall function here
                ;;
            2)
                echo "The Fail2ban configuration functionality has not yet been implemented."
                fail2ban  # Call your fail2ban function here
                ;;
            3)
                echo "The WAF firewall configuration functionality is not yet implemented."
                waf  # Call your WAF function here
                ;;
            4)
                echo "The Security-Enhanced Linux (SELinux) configuration functionality has not yet been implemented."
                selinux  # Call your SELinux function here
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 4."
                ;;
        esac
    done
}

function users() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > \e[1mUsers\e[0m"
        echo "Select an action:"
        echo "1) Create User"
        echo "2) Delete User"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 2: " REPLY

        case $REPLY in
            1)
                echo "You chose Create User"
                create_user  # Call your create_user function here
                ;;
            2)
                echo "You chose Delete User"
                delete_user  # Call your delete_user function here
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 2."
                ;;
        esac
    done
}

function iptables_services() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Services > \e[1mIPTables Services\e[0m"
        echo "Select an action:"
        echo "1) Start services"
        echo "2) Stop services"
        echo "3) Restart services"
        echo "4) Status services"
        echo "5) Adding services to startup"
        echo "6) Remove services from startup"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 6: " REPLY

        case $REPLY in
            1)
                status=$(/usr/bin/systemctl is-active iptables)
                if [[ $status == "active" ]]; then
                    echo -e "\e[32mService is already running.\e[0m"
                    sleep 2
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStarting IPTables...\e[0m"
                /usr/bin/systemctl start iptables
                /usr/bin/systemctl start ip6tables
                ;;
            2)
                status=$(/usr/bin/systemctl is-active iptables)
                if [[ $status == "inactive" ]]; then
                    echo -e "\e[31mService is already stopped.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStopping IPTables...\e[0m"
                /usr/bin/systemctl stop iptables

                status=$(/usr/bin/systemctl is-active iptables)
                if [[ $status == "inactive" ]]; then
                    echo -e "\e[31mService is already stopped.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStopping IPTables...\e[0m"
                /usr/bin/systemctl stop ip6tables
                ;;
            3)
                echo -e "\e[32mRestarting IPTables...\e[0m"
                /usr/bin/systemctl restart iptables
                /usr/bin/systemctl restart ip6tables
                ;;
            4)
                check_service_status_iptables
                ;;
            5)
                enabled=$(/usr/bin/systemctl is-enabled iptables)
                if [[ $enabled == "enabled" ]]; then
                    echo -e "\e[32mService is already added to autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mAdding IPTables to autostart...\e[0m"
                /usr/bin/systemctl enable iptables

                enabled=$(/usr/bin/systemctl is-enabled ip6tables)
                if [[ $enabled == "enabled" ]]; then
                    echo -e "\e[32mService is already added to autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mAdding IP6Tables to autostart...\e[0m"
                /usr/bin/systemctl enable ip6tables
                ;;
            6)
                enabled=$(/usr/bin/systemctl is-enabled iptables)
                if [[ $enabled == "disabled" ]]; then
                    echo -e "\e[31mService is already removed from autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mRemoving IPTables from autostart...\e[0m"
                /usr/bin/systemctl disable iptables

                enabled=$(/usr/bin/systemctl is-enabled ip6tables)
                if [[ $enabled == "disabled" ]]; then
                    echo -e "\e[31mService is already removed from autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mRemoving IP6Tables from autostart...\e[0m"
                /usr/bin/systemctl disable ip6tables
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 6."
                ;;
        esac
    done
}

function nginx_services() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Services > \e[1mNginx Services\e[0m"
        echo "Select an action:"
        echo "1) Start services"
        echo "2) Stop services"
        echo "3) Restart services"
        echo "4) Status services"
        echo "5) Adding services to startup"
        echo "6) Remove services from startup"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 6: " REPLY

        case $REPLY in
            1)
                status=$(/usr/bin/systemctl is-active nginx)
                if [[ $status == "active" ]]; then
                    echo -e "\e[32mService is already running.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStarting Nginx...\e[0m"
                /usr/bin/systemctl start nginx
                sleep 2
                ;;
            2)
                status=$(/usr/bin/systemctl is-active nginx)
                if [[ $status == "inactive" ]]; then
                    echo -e "\e[31mService is already stopped.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStopping Nginx...\e[0m"
                /usr/bin/systemctl stop nginx
                sleep 2
                ;;
            3)
                echo -e "\e[32mRestarting Nginx...\e[0m"
                /usr/bin/systemctl restart nginx
                sleep 2
                ;;
            4)
                check_service_status_nginx
                ;;
            5)
                enabled=$(/usr/bin/systemctl is-enabled nginx)
                if [[ $enabled == "enabled" ]]; then
                    echo -e "\e[32mService is already added to autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mAdding Nginx to autostart...\e[0m"
                /usr/bin/systemctl enable nginx
                ;;
            6)
                enabled=$(/usr/bin/systemctl is-enabled nginx)
                if [[ $enabled == "disabled" ]]; then
                    echo -e "\e[31mService is already removed from autostart.\e[0m"
                    continue
                fi
                echo -e "\e[32mRemoving Nginx from autostart...\e[0m"
                /usr/bin/systemctl disable nginx
                sleep 2
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 6."
                ;;
        esac
    done
}

function fail2ban_services() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Services > \e[1mFail2Ban Services\e[0m"
        echo "Select an action:"
        echo "1) Start services"
        echo "2) Stop services"
        echo "3) Restart services"
        echo "4) Status services"
        echo "5) Adding services to startup"
        echo "6) Remove services from startup"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 6: " REPLY

        case $REPLY in
            1)
                status=$(/usr/bin/systemctl is-active fail2ban)
                if [[ $status == "active" ]]; then
                    echo -e "\e[32mService is already running.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStarting Fail2Ban...\e[0m"
                /usr/bin/systemctl start fail2ban
                sleep 2
                ;;
            2)
                status=$(/usr/bin/systemctl is-active fail2ban)
                if [[ $status == "inactive" ]]; then
                    echo -e "\e[31mService is already stopped.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStopping Fail2Ban...\e[0m"
                /usr/bin/systemctl stop fail2ban
                sleep 2
                ;;
            3)
                echo -e "\e[32mRestarting Fail2Ban...\e[0m"
                /usr/bin/systemctl restart fail2ban
                sleep 2
                ;;
            4)
                check_service_status_fail2ban
                ;;
            5)
                enabled=$(/usr/bin/systemctl is-enabled fail2ban)
                if [[ $enabled == "enabled" ]]; then
                    echo -e "\e[32mService is already added to autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mAdding Fail2Ban to autostart...\e[0m"
                /usr/bin/systemctl enable fail2ban
                ;;
            6)
                enabled=$(/usr/bin/systemctl is-enabled fail2ban)
                if [[ $enabled == "disabled" ]]; then
                    echo -e "\e31mService is already removed from autostart.\e0m"
                    continue
                fi
                echo -e "\e32mRemoving Fail2Ban from autostart...\e0m"
                /usr/bin/systemctl disable fail2ban
                sleep 2
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 6."
                ;;
        esac
    done
}


function php_fpm_services7_4() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Services > PHP-FPM Services > \e[1mPHP-FPM-7.4 Services\e[0m"
        echo "Select an action:"
        echo "1) Start services"
        echo "2) Stop services"
        echo "3) Restart services"
        echo "4) Status services"
        echo "5) Adding services to startup"
        echo "6) Remove services from startup"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 6: " REPLY

        case $REPLY in
            1)
                status=$(/usr/bin/systemctl is-active php74-php-fpm)
                if [[ $status == "active" ]]; then
                    echo -e "\e[32mService is already running.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStarting PHP-FPM-7.4...\e[0m"
                /usr/bin/systemctl start php74-php-fpm
                sleep 2
                ;;
            2)
                status=$(/usr/bin/systemctl is-active php74-php-fpm)
                if [[ $status == "inactive" ]]; then
                    echo -e "\e[31mService is already stopped.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStopping PHP-FPM-7.4...\e[0m"
                /usr/bin/systemctl stop php74-php-fpm
                sleep 2
                ;;
            3)
                echo -e "\e[32mRestarting PHP-FPM-7.4...\e[0m"
                /usr/bin/systemctl restart php74-php-fpm
                sleep 2
                ;;
            4)
                check_service_status_php_fpm php74-php-fpm
                ;;
            5)
                enabled=$(/usr/bin/systemctl is-enabled php74-php-fpm)
                if [[ $enabled == "enabled" ]]; then
                    echo -e "\e[32mService is already added to autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mAdding PHP-FPM-7.4 to autostart...\e[0m"
                /usr/bin/systemctl enable php74-php-fpm
                ;;
            6)
                enabled=$(/usr/bin/systemctl is-enabled php74-php-fpm)
                if [[ $enabled == "disabled" ]]; then
                    echo -e "\e[31mService is already removed from autostart.\e[0m"
                    continue
                fi
                echo -e "\e[32mRemoving PHP-FPM-7.4 from autostart...\e[0m"
                /usr/bin/systemctl disable php74-php-fpm
                sleep 2
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 6."
                ;;
        esac
    done
}

function php_fpm_services8_0() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Services > PHP-FPM Services > \e[1mPHP-FPM-8.0 Services\e[0m"
        echo "Select an action:"
        echo "1) Start services"
        echo "2) Stop services"
        echo "3) Restart services"
        echo "4) Status services"
        echo "5) Adding services to startup"
        echo "6) Remove services from startup"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 6: " REPLY

        case $REPLY in
            1)
                status=$(/usr/bin/systemctl is-active php80-php-fpm)
                if [[ $status == "active" ]]; then
                    echo -e "\e[32mService is already running.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStarting PHP-FPM-8.0...\e[0m"
                /usr/bin/systemctl start php80-php-fpm
                sleep 2
                ;;
            2)
                status=$(/usr/bin/systemctl is-active php80-php-fpm)
                if [[ $status == "inactive" ]]; then
                    echo -e "\e[31mService is already stopped.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStopping PHP-FPM-8.0...\e[0m"
                /usr/bin/systemctl stop php80-php-fpm
                sleep 2
                ;;
            3)
                echo -e "\e[32mRestarting PHP-FPM-8.0...\e[0m"
                /usr/bin/systemctl restart php80-php-fpm
                sleep 2
                ;;
            4)
                check_service_status_php_fpm php80-php-fpm
                ;;
            5)
                enabled=$(/usr/bin/systemctl is-enabled php80-php-fpm)
                if [[ $enabled == "enabled" ]]; then
                    echo -e "\e[32mService is already added to autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mAdding PHP-FPM-8.0 to autostart...\e[0m"
                /usr/bin/systemctl enable php80-php-fpm
                ;;
            6)
                enabled=$(/usr/bin/systemctl is-enabled php80-php-fpm)
                if [[ $enabled == "disabled" ]]; then
                    echo -e "\e[31mService is already removed from autostart.\e[0m"
                    continue
                fi
                echo -e "\e[32mRemoving PHP-FPM-8.0 from autostart...\e[0m"
                /usr/bin/systemctl disable php80-php-fpm
                sleep 2
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 6."
                ;;
        esac
    done
}

function php_fpm_services8_1() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Services > PHP-FPM Services > \e[1mPHP-FPM-8.1 Services\e[0m"
        echo "Select an action:"
        echo "1) Start services"
        echo "2) Stop services"
        echo "3) Restart services"
        echo "4) Status services"
        echo "5) Adding services to startup"
        echo "6) Remove services from startup"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 6: " REPLY

        case $REPLY in
            1)
                status=$(/usr/bin/systemctl is-active php81-php-fpm)
                if [[ $status == "active" ]]; then
                    echo -e "\e[32mService is already running.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStarting PHP-FPM-8.1...\e[0m"
                /usr/bin/systemctl start php81-php-fpm
                sleep 2
                ;;
            2)
                status=$(/usr/bin/systemctl is-active php81-php-fpm)
                if [[ $status == "inactive" ]]; then
                    echo -e "\e[31mService is already stopped.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStopping PHP-FPM-8.1...\e[0m"
                /usr/bin/systemctl stop php81-php-fpm
                sleep 2
                ;;
            3)
                echo -e "\e[32mRestarting PHP-FPM-8.1...\e[0m"
                /usr/bin/systemctl restart php81-php-fpm
                sleep 2
                ;;
            4)
                check_service_status_php_fpm php81-php-fpm
                ;;
            5)
                enabled=$(/usr/bin/systemctl is-enabled php81-php-fpm)
                if [[ $enabled == "enabled" ]]; then
                    echo -e "\e[32mService is already added to autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mAdding PHP-FPM-8.1 to autostart...\e[0m"
                /usr/bin/systemctl enable php81-php-fpm
                ;;
            6)
                enabled=$(/usr/bin/systemctl is-enabled php81-php-fpm)
                if [[ $enabled == "disabled" ]]; then
                    echo -e "\e[31mService is already removed from autostart.\e[0m"
                    continue
                fi
                echo -e "\e[32mRemoving PHP-FPM-8.1 from autostart...\e[0m"
                /usr/bin/systemctl disable php81-php-fpm
                sleep 2
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 6."
                ;;
        esac
    done
}

function php_fpm_services8_2() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Services > PHP-FPM Services > \e[1mPHP-FPM-8.2 Services\e[0m"
        echo "Select an action:"
        echo "1) Start services"
        echo "2) Stop services"
        echo "3) Restart services"
        echo "4) Status services"
        echo "5) Adding services to startup"
        echo "6) Remove services from startup"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 6: " REPLY

        case $REPLY in
            1)
                status=$(/usr/bin/systemctl is-active php82-php-fpm)
                if [[ $status == "active" ]]; then
                    echo -e "\e[32mService is already running.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStarting PHP-FPM-8.2...\e[0m"
                /usr/bin/systemctl start php82-php-fpm
                sleep 2
                ;;
            2)
                status=$(/usr/bin/systemctl is-active php82-php-fpm)
                if [[ $status == "inactive" ]]; then
                    echo -e "\e[31mService is already stopped.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStopping PHP-FPM-8.2...\e[0m"
                /usr/bin/systemctl stop php82-php-fpm
                sleep 2
                ;;
            3)
                echo -e "\e[32mRestarting PHP-FPM-8.2...\e[0m"
                /usr/bin/systemctl restart php82-php-fpm
                sleep 2
                ;;
            4)
                check_service_status_php_fpm php82-php-fpm
                ;;
            5)
                enabled=$(/usr/bin/systemctl is-enabled php82-php-fpm)
                if [[ $enabled == "enabled" ]]; then
                    echo -e "\e[32mService is already added to autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mAdding PHP-FPM-8.2 to autostart...\e[0m"
                /usr/bin/systemctl enable php82-php-fpm
                ;;
            6)
                enabled=$(/usr/bin/systemctl is-enabled php82-php-fpm)
                if [[ $enabled == "disabled" ]]; then
                    echo -e "\e[31mService is already removed from autostart.\e[0m"
                    continue
                fi
                echo -e "\e[32mRemoving PHP-FPM-8.2 from autostart...\e[0m"
                /usr/bin/systemctl disable php82-php-fpm
                sleep 2
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 6."
                ;;
        esac
    done
}

function php_fpm_services8_3() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Services > PHP-FPM Services > \e[1mPHP-FPM-8.3 Services\e[0m"
        echo "Select an action:"
        echo "1) Start services"
        echo "2) Stop services"
        echo "3) Restart services"
        echo "4) Status services"
        echo "5) Adding services to startup"
        echo "6) Remove services from startup"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 6: " REPLY

        case $REPLY in
            1)
                status=$(/usr/bin/systemctl is-active php83-php-fpm)
                if [[ $status == "active" ]]; then
                    echo -e "\e[32mService is already running.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStarting PHP-FPM-8.3...\e[0m"
                /usr/bin/systemctl start php83-php-fpm
                sleep 2
                ;;
            2)
                status=$(/usr/bin/systemctl is-active php83-php-fpm)
                if [[ $status == "inactive" ]]; then
                    echo -e "\e[31mService is already stopped.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mStopping PHP-FPM-8.3...\e[0m"
                /usr/bin/systemctl stop php83-php-fpm
                sleep 2
                ;;
            3)
                echo -e "\e[32mRestarting PHP-FPM-8.3...\e[0m"
                /usr/bin/systemctl restart php83-php-fpm
                sleep 2
                ;;
            4)
                check_service_status_php_fpm php83-php-fpm
                ;;
            5)
                enabled=$(/usr/bin/systemctl is-enabled php83-php-fpm)
                if [[ $enabled == "enabled" ]]; then
                    echo -e "\e[32mService is already added to autostart.\e[0m"
                    sleep 2
                    continue
                fi
                echo -e "\e[32mAdding PHP-FPM-8.3 to autostart...\e[0m"
                /usr/bin/systemctl enable php83-php-fpm
                ;;
            6)
                enabled=$(/usr/bin/systemctl is-enabled php83-php-fpm)
                if [[ $enabled == "disabled" ]]; then
                    echo -e "\e[31mService is already removed from autostart.\e[0m"
                    continue
                fi
                echo -e "\e[32mRemoving PHP-FPM-8.3 from autostart...\e[0m"
                /usr/bin/systemctl disable php83-php-fpm
                sleep 2
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 6."
                ;;
        esac
    done
}

function php_fpm_services() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Services > \e[1mPHP-FPM  Services\e[0m"
        echo "Select an action:"
        echo "1) PHP-FPM-7.4"
        echo "2) PHP-FPM-8.0"
        echo "3) PHP-FPM-8.1"
        echo "4) PHP-FPM-8.2"
        echo "5) PHP-FPM-8.3"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 5: " REPLY

        case $REPLY in
            1)
                echo "You chose Users"
                php_fpm_services7_4  # Call your php_fpm_services7_4 function here
                ;;
            2)
                echo "You chose Security"
                php_fpm_services8_0  # Call your Security function here
                ;;
            3)
                echo "You chose Services"
                php_fpm_services8_1  # Call your Services function here
                ;;
            4)
                echo "You chose Services"
                php_fpm_services8_2  # Call your Services function here
                ;;
            5)
                echo "You chose Services"
                php_fpm_services8_3  # Call your Services function here
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 5."
                ;;
        esac
    done
}

function services() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > \e[1mServices\e[0m"
        echo "Select an action:"
        echo "1) MariaDB"
        echo "2) Nginx"
        echo "3) PHP-FPM"
        echo "4) IPTables"
        echo "5) Fail2ban"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 6: " REPLY

        case $REPLY in
            1)
                echo "You chose Users"
                mariadb_services  # Call your users function here
                ;;
            2)
                echo "You chose Security"
                nginx_services  # Call your Security function here
                ;;
            3)
                echo "You chose Services"
                php_fpm_services  # Call your Services function here
                ;;
            4)
                echo "You chose Services"
                iptables_services  # Call your Services function here
                ;;
            5)
                echo "You chose Services"
                fail2ban_services  # Call your Services function here
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 5."
                ;;
        esac
    done
}

function repositories() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Applications > \e[1mRepositories\e[0m"
        echo "Select an action to add a repository:"
        echo "1) MariaDB"
        echo "2) Nginx"
        echo "3) Remi"
        echo "4) Epel"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 4: " REPLY

        case $REPLY in
            1)
                echo "You chose Users"
                add_mariadb_repo  # Call your add_mariadb_repo function here
                ;;
            2)
                echo "You chose Security"
                add_nginx_repo  # Call your add_nginx_repo function here
                ;;
            3)
                echo "You chose Services"
                check_and_install_repo  # Call your check_and_install_repo function here
                ;;
            4)
                echo "You chose Services"
                add_epel_repo  # Call your add_epel_repo function here
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 4."
                ;;
        esac
    done
}

function install_packages() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > Applications > \e[1mInstall Packages\e[0m"
        echo "Select a package to install:"
        echo "1) MariaDB"
        echo "2) Nginx"
        echo "3) Let's Encrypt"
        echo "4) PHP"
        echo "5) Fail2ban"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 5: " REPLY

        case $REPLY in
            1)
                echo "You chose Services"
                install_mariadb  # Call your install_mariadb function here
                ;;
            2)
                echo "You chose Security"
                install_nginx  # Call your install_nginx function here
                ;;
            3)
                echo "You chose Services"
                install_letsencrypt  # Call your install_letsencrypt function here
                ;;
            4)
                echo "You chose Services"
                install_php  # Call your add_epel_repo function here
                ;;
            5)
                echo "You chose Services"
                install_fail2ban  # Call your install_php function here
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 4."
                ;;
        esac
    done
}

function applications() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > Settings > \e[1mApplications\e[0m"
        echo "Select an action:"
        echo "1) Repositories"
        echo "2) Install Packages"
        echo "3) Remove Packages"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 3: " REPLY

        case $REPLY in
            1)
                echo "You chose Users"
                repositories  # Call your repositories function here
                ;;
            2)
                echo "You chose Security"
                install_packages  # Call your install_packages function here
                ;;
            3)
                echo "You chose Services"
                remove_packages  # Call your remove_packages function here
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 4."
                ;;
        esac
    done
}
function settings() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "Main menu > \e[1mSettings\e[0m"
        echo "Select an action:"
        echo "1) Users"
        echo "2) Security"
        echo "3) Services"
        echo "4) Applications"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 4: " REPLY

        case $REPLY in
            1)
                echo "You chose Users"
                users  # Call your users function here
                ;;
            2)
                echo "You chose Security"
                security  # Call your Security function here
                ;;
            3)
                echo "You chose Services"
                services  # Call your Services function here
                ;;
            4)
                echo "You chose Applications"
                applications  # Call your Applications function here
                ;;
            0)
                echo "Returning to the main menu"
                return  # Exit the function and the outer while loop
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 4."
                ;;
        esac
    done
}

function main_menu() {
    while true; do
        clear  # Clear the screen
        display_header
        echo -e "\e[1mMain menu\e[0m"
        echo "Select an action:"
        echo "1) MariaDB Server"
        echo "2) WEB Server"
        echo "3) Settings"
        echo "0) Exit"
        read -p "Enter numbers from 0 to 3: " REPLY

        case $REPLY in
            1)
                echo "You chose MariaDB Server"
                mysql_server  # Call your mysql_server function here
                ;;
            2)
                echo "You chose WEB Server"
                lemp_server  # Call your lemp_server function here
                ;;
            3)
                echo "You chose Settings"
                settings  # Call your settings function here
                ;;
            0)
                echo "Exiting and ending the script"
                break  # Exiting and ending the script
                ;;
            *)
                echo "Invalid choice. Select numbers from 0 to 3."
                ;;
        esac
    done
}

main_menu
