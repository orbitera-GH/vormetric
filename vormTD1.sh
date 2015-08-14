#!/bin/bash -l
export HOME=/tmp
echo "start." >> /custom.log
azure login john@orbitera.onmicrosoft.com -p BXD01test
azure account list
azure account set 6313375e-ba66-4c07-89ef-3a02568fd43e
azure config mode arm
echo "zabawa z hostname start..."
new_hostname=`echo ${HOSTNAME} | tr '[:upper:]' '[:lower:]'`
echo "nazwa hosta z new_hostname: $new_hostname"

#azure storage blob copy start -a vormetric1td -k "1r8kOko8Xrd81ej3WJyIGZu+7YQAx8C0L0bkIg1ZTSuEmcuU3cPmNI2DmSwkoPix1rAWiGAfWOvKxLGx6FQRKQ==" --dest-blob "vormetric-${HOSTNAME,,}-image-v2.vhd"  --source-uri https://vormetric1td.blob.core.windows.net/img/vormetric-image-v2.vhd --dest-container vhds
azure storage blob copy start -a vormetric1td -k "1r8kOko8Xrd81ej3WJyIGZu+7YQAx8C0L0bkIg1ZTSuEmcuU3cPmNI2DmSwkoPix1rAWiGAfWOvKxLGx6FQRKQ==" --dest-blob "vormetric-$new_hostname-image-v2.vhd"  --source-uri https://vormetric1td.blob.core.windows.net/img/vormetric-image-v2.vhd --dest-container vhds

#grupa="orbiteratestdrive${HOSTNAME#*-}"
grupa=`echo ${HOSTNAME} | cut -d - -f2`

#azure vm create -g $grupa -n VormmetricMain -l westeurope -y linux --vnet-name "${HOSTNAME,,}-net" -d "https://vormetric1td.blob.core.windows.net/vhds/vormetric-${HOSTNAME,,}-image-v2.vhd" -o vormetric1td -R vhds -f vormMainNic --vnet-subnet-name "Subnet-2"
azure vm create -g $grupa -n VormmetricMain -l westeurope -y linux --vnet-name "$new_hostname-net" -d "https://vormetric1td.blob.core.windows.net/vhds/vormetric-${HOSTNAME,,}-image-v2.vhd" -o vormetric1td -R vhds -f vormMainNic --vnet-subnet-name "Subnet-2"

echo "stop." >> /custom.log
