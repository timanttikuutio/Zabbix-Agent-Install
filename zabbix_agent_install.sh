#!/usr/bin/bash

if [ -n "$1" ]; then
agent_config="# This is a configuration file for Zabbix agent daemon (Unix)
LogFile=/var/log/zabbix-agent/zabbix_agentd.log
LogFileSize=0

Server=$1
ListenPort=10050

ServerActive=127.0.0.1
"
else
    echo "Error: please specify your Zabbix server as an argument. Example: bash zabbix_agent_install.sh 192.168.1.61. Replace the IP with your zabbix server."
    exit 1
fi

if ! command -v zabbix_agentd >/dev/null; then
    if [ "$(lsb_release -is)" = "Ubuntu" ]; then
        echo "Ubuntu detected, continuing with install."

        apt-get update -y > /dev/null
        apt-get install zabbix-agent -y > /dev/null

        systemctl enable --now zabbix-agent
    elif [ "$(lsb_release -is)" = "Debian" ]; then
        echo "Debian detected, continuing with install."

        apt-get update -y > /dev/null
        apt-get install zabbix-agent -y > /dev/null

        systemctl enable --now zabbix-agent
    elif [ "$(lsb_release -is)" = "Arch" ]; then
        echo "Arch detected, continuing with install."

        pacman -Syu > /dev/null
        yes | pacman -S zabbix-agent > /dev/null

        systemctl enable --now zabbix-agent
    elif [ "$(lsb_release -is)" = "Vyos" ]; then
        echo "Vyos detected, continuing with install."

        apt update > /dev/null
        apt install zabbix-agent > /dev/null

        systemctl enable --now zabbix-agent
    else
      echo "Your distribution \"$(lsb_release  -is) $(lsb_release  -rs)\" is not supported."
      exit
    fi
else
    echo "Warning: Zabbix agent is already installed. Skipping installation. Would you like to continue with the configuration(y/n)? "
    read -r skip_install_prompt

    if [ ! "$skip_install_prompt" = "y" ]; then
        echo "cancelling installation."
        exit 1
    fi
fi

echo "$agent_config" > /etc/zabbix/zabbix_agentd.conf

ip=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
hostname=$(cat /etc/hostname)

if [ "$2" = "yes" ]; then
    if ! command -v openssl >/dev/null; then
        echo "OpenSSL package is not installed, cannot continue with pre-shared key generation."
    else
        zabbix_psk="$(openssl rand -hex 32)"

        echo "$zabbix_psk" > /etc/zabbix/zabbix_agentd.psk

        updated_agent_config="
TLSConnect=psk
TLSAccept=psk
TLSPSKFile=/etc/zabbix/zabbix_agentd.psk
TLSPSKIdentity=$hostname
"
        echo "$updated_agent_config" >> /etc/zabbix/zabbix_agentd.conf

        printf "PSK for the Zabbix agent generated and saved at /etc/zabbix/zabbix_agentd.psk, details below.\n\nPSK identity: $hostname\nPSK: %s\n\n" "$zabbix_psk"
    fi
fi

echo "Zabbix configuration saved at /etc/zabbix/zabbix_agentd.conf."

systemctl restart zabbix-agent
echo "Restarted Zabbix agent"

echo "The Zabbix agent has been installed and configured. Your primary IP is $ip and the hostname is $hostname"
