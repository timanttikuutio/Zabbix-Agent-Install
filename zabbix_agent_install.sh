apt install lsb-release -y

if [ -n $1 ]; then
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

echo "$agent_config" > /etc/zabbix/zabbix_agentd.conf

echo "Zabbix configuration saved at /etc/zabbix/zabbix_agentd.conf."

ip=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
hostname=$(cat /etc/hostname)

systemctl restart zabbix-agent
echo "Restarted Zabbix agent"

echo "The Zabbix agent has been installed and configured. Your primary IP is $ip and the hostname is $hostname"
