#!/bin/bash
echo "czekaczka start" >> /tmp/custom.log
HOSTNAME=`hostname`
new_hostname=`echo ${HOSTNAME} | tr '[:upper:]' '[:lower:]'`
ID=`echo ${new_hostname} | cut -d - -f2`
haslo="MySec$ID"
echo "takie tam.. has: $haslo" >> /tmp/custom.log
#echo -e "$haslo\n$haslo" | sudo passwd root
echo root:$haslo | sudo chpasswd
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo restart ssh

while ! curl -k https://10.0.76.4/ >/dev/null 2>/dev/null; do
   echo "Waiting..." >> /tmp/custom.log
   sleep 20
done
echo "...and..." >> /tmp/custom.log
sleep 20
while [ "`curl -s -o /dev/null -I -w "%{http_code}" -k https://10.0.76.4/`" != "200" ]; do
   echo "Waiting..." >> /tmp/custom.log
   sleep 20
done
echo "czekaczka stop." >> /tmp/custom.log