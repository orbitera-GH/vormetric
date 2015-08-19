#!/bin/bash -l
echo "czekaczka start" >> /custom.log
while ! curl -k https://10.0.76.4/ >/dev/null 2>/dev/null; do
   echo "Waiting..." >> /custom.log
   sleep 10
done
	sleep 60
echo "czekaczka stop." >> /custom.log
