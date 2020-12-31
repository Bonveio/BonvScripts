#!/bin/bash
# Configure SSH Daemon to Permit access root remotely via OpenSSH server
# Author: Bonveio <github.com/Bonveio/BonvScripts>

# Check if machine has a sudo package
if [[ ! "$(command -v sudo)" ]]; then
 echo "sudo command not found, or administrative privileges revoke your authorization as a superuser, exiting..."
 exit 1
fi

until [[ "$newsshpassh" =~ ^[a-zA-Z0-9_]+$ ]]; do
read -rp " Enter your new Root Password: " -e newsshpassh
done

# Check if machine throws bad config error
# Then fix it 
if [[ "$(sudo sshd -T | grep -c "Bad configuration")" -eq 1 ]]; then
 sudo service ssh restart &> /dev/null
 sudo service sshd restart &> /dev/null
 sudo cat <<'eof' > /etc/ssh/sshd_config
Port 22
AddressFamily inet
ListenAddress 0.0.0.0
Protocol 2
#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_dsa_key
#ServerKeyBits 1024
PermitRootLogin yes
MaxSessions 1024
PubkeyAuthentication yes
PermitEmptyPasswords no
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
#AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
#AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
#AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
#AcceptEnv XMODIFIERS
AllowAgentForwarding yes
X11Forwarding yes
PrintMotd no
ClientAliveInterval 120
ClientAliveCountMax 2
UseDNS no
Subsystem sftp  /usr/libexec/openssh/sftp-server
eof
fi

# Checking ssh daemon if PermitRootLogin is not allowed yet
if [[ "$(sudo sshd -T | grep -i "permitrootlogin" | awk '{print $2}')" != "yes" ]]; then
 echo "Allowing PermitRootLogin..."
 sudo sed -i '/PermitRootLogin.*/d' /etc/ssh/sshd_config &> /dev/null
 sudo sed -i '/#PermitRootLogin.*/d' /etc/ssh/sshd_config &> /dev/null
 echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
 else
 echo "PermitRootLogin already allowed.."
fi

# Checking if PasswordAuthentication is not allowed yet
if [[ "$(sudo sshd -T | grep -i "passwordauthentication" | awk '{print $2}')" != "yes" ]]; then
 echo "Allowing PasswordAuthentication..."
 sudo sed -i '/PasswordAuthentication.*/d' /etc/ssh/sshd_config &> /dev/null
 sudo sed -i '/#PasswordAuthentication.*/d' /etc/ssh/sshd_config &> /dev/null
 echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
 else
 echo "PasswordAuthentication already allowed"
fi

# Changing root Password
echo -e "$newsshpassh\n$newsshpassh\n" | sudo passwd root &> /dev/null

# Restarting OpenSSH Service to save all of our changes
echo "Restarting openssh service..."
if [[ ! "$(command -v systemctl)" ]]; then
 sudo service ssh restart &> /dev/null
 sudo service sshd restart &> /dev/null
 else
 sudo systemctl restart ssh &> /dev/null
 sudo systemctl restart sshd &> /dev/null
fi

echo -e "\nNow check if your SSH are accessible using root\nIP Address: $(wget -4qO- http://ipinfo.io/ip || curl -4sSL http://ipinfo.io/ip)\nSSH Port: $(sudo ss -4tlnp | grep -i "ssh" | awk '{print $4}' | cut -d: -f2 | head -n1)\nRoot Password: $newsshpassh\n"

exit 0
