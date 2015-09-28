#!/bin/dash

#set -x
exec 1>>/tmp/custom.log

# helper variables
HOSTNAME=$(hostname | tr '[:upper:]' '[:lower:]')
ID=$(echo ${HOSTNAME} | cut -d - -f2)
ID3=$(echo ${ID} | awk '{ print substr($0, 3, 3); }')

. /opt/vormetric/cloudtools/defaults

ADMIN_PASS="WqTr^s${ID3}"
CLIADMIN_PASS="DsMp@s${ID3}"

AZURE_DOMAIN="azdomain"
AZURE_ADMIN="azadmin"
AZURE_ADMIN_PASS="WcAp#N${ID3}"

ROOT_PASS="MySec${ID}"
GOODGUY_PASS="${ID}gdg"
BADGUY_PASS="bdd${ID}"

HOST_PASS="Abcd1234#"

CLOUDTOOLS_DIR="/opt/vormetric/cloudtools"
LICENSE_FILE="${CLOUDTOOLS_DIR}/license"
POLICY_FILE="${CLOUDTOOLS_DIR}/basicpolicy.xml"
VMSSC="${CLOUDTOOLS_DIR}/vmssc"

echo "czekaczka start"

# change local passwords

sudo chpasswd <<EOF
root:${ROOT_PASS}
good-guy:${GOODGUY_PASS}
bad-guy:${BADGUY_PASS}
EOF

# wait for DSM...

echo "Wait for ${DSM_HOST}..."

while ! ping -c1 -W1 ${DSM_HOST} >/dev/null; do
    echo "Host ${DSM_HOST} ping timeout..."
    sleep 5
done

echo "Host ${DSM_HOST} ping succeeded"

echo "Wait for ssh on ${DSM_HOST}..."

while ! nc -z ${DSM_HOST} 22; do
    echo "Waiting..."
    sleep 2
done

echo "Wait a moment to settle down..."
sleep 10

while ! expect -d - <<EOF
set timeout 300

spawn ssh ${DEFAULT_CLIADMIN}@${DSM_HOST}

expect "yes/no" {
    send "yes\n"
    expect "*?assword" { send "${DEFAULT_CLIADMIN_PASS}\n" }
    } "*?assword" { send "${DEFAULT_CLIADMIN_PASS}\n" }

expect {
    "CLI daemon is not running." {
        exit 1
    }
    
    "Enter new password  : " {
        send "${CLIADMIN_PASS}\n"
    }
}

expect "Enter password again: "
send "${CLIADMIN_PASS}\n"
expect "vormetric\\\$ "
send "system\n"
expect "system\\\$ "
send "security genca\n"
expect "Continue?"
send "yes\n"
expect "your.name.here.com"
send "\n"
expect "What is the name of your organizational unit?"
send "${DSM_CA_OU}\n"
expect "What is the name of your organization?"
send "${DSM_CA_O}\n"
expect "What is the name of your City or Locality?"
send "${DSM_CA_L}\n"
expect "What is the name of your State or Province?"
send "${DSM_CA_ST}\n"
expect "What is your two-letter country code?"
send "${DSM_CA_C}\n"
sleep 1
expect "system\\\$ "
send "exit\n"
exit 0
EOF
do
    echo "Something went wrong with expect, retrying..."
    sleep 2
done

echo "Wait for DSM web server..."

while ! nc -z ${DSM_HOST} 443; do
    echo "Waiting..."
    sleep 5
done

echo "Port 443 is open, check if application is running..."

while [ "$(curl -s -o /dev/null -I -w "%{http_code}" -k https://10.0.76.4/)" != "200" ]; do
   echo "Waiting..."
   sleep 10
done

echo "OK, web application is running, yupi!"

echo "Proceed to configuration..."

echo "Change password for ${DEFAULT_ADMIN} user..."
${VMSSC} -s ${DSM_HOST} -u ${DEFAULT_ADMIN} -p ${DEFAULT_ADMIN_PASS} user modify -p ${ADMIN_PASS} ${DEFAULT_ADMIN}
echo "Add user ${AZURE_ADMIN}..."
${VMSSC} -s ${DSM_HOST} -u ${DEFAULT_ADMIN} -p ${ADMIN_PASS} user add -p ${ADMIN_PASS} -t All ${AZURE_ADMIN}
echo "Set password for ${AZURE_ADMIN}..."
${VMSSC} -s ${DSM_HOST} -u ${AZURE_ADMIN} -p ${ADMIN_PASS} user modify -p ${AZURE_ADMIN_PASS} ${AZURE_ADMIN}
echo "Install license file..."
${VMSSC} -s  ${DSM_HOST} -u ${DEFAULT_ADMIN} -p ${ADMIN_PASS} server license -f ${LICENSE_FILE}
echo "Create domain ${AZURE_DOMAIN}..."
${VMSSC} -s ${DSM_HOST} -u ${DEFAULT_ADMIN} -p ${ADMIN_PASS} domain add -u ${AZURE_ADMIN} ${AZURE_DOMAIN}
echo "Create key..."
${VMSSC} -s ${DSM_HOST} -u ${AZURE_ADMIN} -p ${AZURE_ADMIN_PASS} -d ${AZURE_DOMAIN} key add -t AES256 -h aes256
echo "Import basic policy..."
${VMSSC} -s ${DSM_HOST} -u ${AZURE_ADMIN} -p ${AZURE_ADMIN_PASS} -d ${AZURE_DOMAIN} policy save -d basic-access-policy -f ${POLICY_FILE} basic-access-policy
echo "Register agent host..."
${VMSSC} -s ${DSM_HOST} -u ${AZURE_ADMIN} -p ${AZURE_ADMIN_PASS} -d ${AZURE_DOMAIN} host add -h ${HOST_PASS} -L perpetual 10.0.76.5
echo "Add protected directory..."
${VMSSC} -s ${DSM_HOST} -u ${AZURE_ADMIN} -p ${AZURE_ADMIN_PASS} -d ${AZURE_DOMAIN} host addgp -d /secure_dir/ -p basic-access-policy 10.0.76.5

echo "Configure host..."
sudo /opt/vormetric/DataSecurityExpert/agent/vmd/bin/register_host silent /opt/vormetric/cloudtools/reg_host.conf

echo "czekaczka stop."
