#!/bin/bash
echo "czekaczka start" >> /tmp/custom.log
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