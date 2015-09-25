#!/bin/bash

echo "czekaczka start" >> /tmp/custom.log

# we *need* expect
#sudo apt-get install -y expect

# also we need to patch sshd config
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo restart ssh

# prepare variables

HOSTNAME=`hostname`
new_hostname=`echo ${HOSTNAME} | tr '[:upper:]' '[:lower:]'`
ID=`echo ${new_hostname} | cut -d - -f2`
ID3=$(echo ${ID} | awk '{ print substr($0, 3, 3); }')

root_passwd="MySec${ID}"
goodguy_passwd="${ID}gdg"
badguy_passwd="bdd${ID}"
cliadmin_passwd="DsMp@s${ID3}"
webadmin_passwd="WcAp#s${ID3}"

echo "takie tam: root pass: ${root_passwd}" >> /tmp/custom.log
echo "takie tam: good-guy pass: ${goodguy_passwd}" >> /tmp/custom.log
echo "takie tam: bad-guy pass: ${badguy_passwd}" >> /tmp/custom.log
echo "takie tam: cliadmin DSM pass: ${cliadmin_passwd}" >> /tmp/custom.log
#echo "takie tam: webadmin DSM pass: ${webadmin_passwd}" >> /tmp/custom.log

# change passwords

sudo chpasswd <<EOF
root:${root_passwd}
good-guy:${goodguy_passwd}
bad-guy:${badguy_passwd}
EOF

# wait for DSM...

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

#... and change cliadmin pass
expect - ${cliadmin_passwd} <<EOF
set timeout 60

spawn ssh cliadmin@10.0.76.4

expect "yes/no" {
    send "yes\r"
    expect "*?assword" { send "cliadmin123\r" }
    } "*?assword" { send "cliadmin123\r" }

expect "Enter new password  : " { send "[lindex \$argv 0]\r" }
expect "Enter password again: " { send "[lindex \$argv 0]\r" }
expect "$ " { send "exit\r" }
EOF

echo "czekaczka stop." >> /tmp/custom.log
