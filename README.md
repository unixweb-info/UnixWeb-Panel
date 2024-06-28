# UnixWeb Panel

Welcome to the UnixWeb Panel project! This Bash script provides a comprehensive control panel for managing your LEMP stack, which includes Linux, Nginx, MySQL (MariaDB), and PHP. The UnixWeb Panel allows you to efficiently manage and monitor your server environment, making it easier to handle various administrative tasks.

This script is designed to automate server management with an emphasis on information security. At the moment, a number of planned functions have not yet been implemented, but the following features are expected to be introduced:

- Configuring SELinux profiles to enhance security and access control.
- Implementation of ModSecurity as a module for Nginx to detect and prevent attacks on web applications.
- Setting up Fail2ban to automatically respond to suspicious activity.

![UnixWeb Panel](https://github.com/unixweb-info/UnixWeb-Panel/blob/main/UnixWebPanel.jpg)

In addition, the following security and management measures are planned to be integrated:

- Installing and configuring a firewall (for example, iptables) to filter network traffic.
- Regular security checks and system audits to identify potential vulnerabilities.
- Setting up a data backup system and recovery mechanisms to ensure data reliability.
- Implementation of monitoring of system and application logs for prompt response to incidents.

## Supported Operating Systems

The UnixWeb Panel script supports the following operating systems:
- **CentOS Stream 9**
- **AlmaLinux 9.x (Seafoam Ocelot)**
- **Rocky Linux 9.x (Blue Onyx)**

Ensure that your server is running one of these supported operating systems before using the script.

## Supported CMS

- WordPress
- 1C-Bitrix
- Joomla
- MODX Revolution
- OpenCart
- Drupal
- DataLife Engine
- Webasyst CMS (Shop-Script)
- UMI.CMS
- cs.cart

## Supported PHP Versions

- PHP-7.4
- PHP-8.0
- PHP-8.1
- PHP-8.2
- PHP-8.3

## Supported MariaDB Versions

- MariaDB-10.4
- MariaDB-10.5
- MariaDB-10.6
- MariaDB-10.10
- MariaDB-10.11
- MariaDB-11.0
- MariaDB-11.1
- MariaDB-11.2
- MariaDB-11.4

## Features

### Service Management
- **MariaDB Management**: Checks if MariaDB is installed and running. If not, it installs and starts the service.
- **Nginx Management**: Adds the official Nginx repository to your system.

### Repository Management
- **Nginx Repository**: Adds both stable and mainline Nginx repositories to your system.
- **EPEL Repository**: Checks for the EPEL repository, installs it if not present, and updates the system.

### Firewall Configuration
- **Iptables Installation**: Installs iptables-services if not already installed.
- **Default Rules Setup**: Configures default iptables rules to secure your server, including allowing traffic on ports 22 (SSH), 80 (HTTP), and 443 (HTTPS).

### SELinux Management
- **SELinux Status Check**: Checks if SELinux is in enforcing mode and sets it to permissive mode if necessary.

## Prerequisites

- The script must be run as the root user.

## Usage

To use this script, follow these steps:

1. **Ensure you are the root user**: The script requires root privileges to execute.
2. **Run the Script**: Execute the script from the terminal.

**Install the UnixWeb panel**
```bash
wget https://raw.githubusercontent.com/unixweb-info/UnixWeb-Panel/main/UnixWebPanelDemo.sh && chmod +x ./UnixWebPanelDemo.sh && sudo ./UnixWebPanelDemo.sh --install
```

**Using the UnixWeb panel**
```bash
sudo ./UnixWebPanelDemo.sh
```

### Detailed Steps

1. **Check OS Compatibility**: The script verifies if your operating system is supported by checking against a list of supported OS versions.
2. **MariaDB Management**: It checks if MariaDB is installed. If not, it installs MariaDB and ensures the service is running.
3. **Add Nginx Repository**: The script adds the official Nginx repository, providing options for both stable and mainline versions.
4. **Add EPEL Repository**: It checks if the EPEL repository is enabled and installs it if not, followed by a system update.
5. **Firewall Configuration**: The script installs iptables-services, disables firewalld, and configures default iptables rules to secure your server.
6. **SELinux Configuration**: Checks the current mode of SELinux and sets it to permissive mode if it’s in enforcing mode.

## Functions

### error_exit
Displays an error message and exits the script.

### check_os
Checks if the current operating system is supported.

### display_header
Displays a welcome header with project information.

### display_header_warning
Displays a header with a warning message.

### check_and_run_mariadb
Checks if MariaDB is installed and running, installs it if not.

### add_nginx_repo
Adds the official Nginx repository.

### add_epel_repo
Adds the EPEL repository if not already present.

### create_default_rules
Creates and applies default iptables rules.

### install_iptables
Installs iptables-services and configures iptables.

### check_and_run_iptables
Checks if iptables-services is installed and running, installs it if not.

### check_selinux_status
Checks the current status of SELinux and sets it to permissive mode if it’s in enforcing mode.

Not all functions are described here; whoever wants to understand the code will understand it. The script is quite simple.

## Contact

For more information or questions about the script, you can contact me at the following contacts:

- **Telegram**: [UnixWebAdmin_info](https://t.me/UnixWebAdmin_info)
- **WhatsApp**: +995 593-245-168
- **Website**: [UnixWeb.info](https://UnixWeb.info)

I am ready to provide support and advice on setting up and using the script for your server.

## License

This project is licensed under the GNU General Public License v3.0.

---

Developed by Kriachko Aleksei © 2024. Enjoy using your LEMP control panel!
