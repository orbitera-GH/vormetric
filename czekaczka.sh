#!/bin/bash -l
echo "czekaczka start" >> /custom.log
while ! curl -k https://10.0.76.4/ >/dev/null 2>/dev/null; do
   echo "Waiting..."
   sleep 10
done
echo "czekaczka stop." >> /custom.log
