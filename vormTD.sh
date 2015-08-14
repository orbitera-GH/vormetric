#!/bin/bash
echo "start." >> /custom.log
azure login john@orbitera.onmicrosoft.com -p BXD01test
azure account list
azure account set 6313375e-ba66-4c07-89ef-3a02568fd43e
azure config mode arm
#echo "nazwa: $HOSTNAME"
azure storage blob copy start -a vormetric1td -k "1r8kOko8Xrd81ej3WJyIGZu+7YQAx8C0L0bkIg1ZTSuEmcuU3cPmNI2DmSwkoPix1rAWiGAfWOvKxLGx6FQRKQ==" --dest-blob "vormetric-${HOSTNAME,,}-image-v2.vhd"  --source-uri https://vormetric1td.blob.core.windows.net/img/vormetric-image-v2.vhd --dest-container vhds

grupa="orbiteratestdrive${HOSTNAME#*-}"
azure vm create -g $grupa -n VormmetricMain -l westeurope -y linux --vnet-name "${HOSTNAME,,}-net" -d "https://vormetric1td.blob.core.windows.net/vhds/vormetric-${HOSTNAME,,}-image-v2.vhd" -o vormetric1td -R vhds -f vormMainNic --vnet-subnet-name "Subnet-2"

echo "stop." >> /custom.log
