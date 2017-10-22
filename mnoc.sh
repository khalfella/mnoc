#!/bin/bash

########## This script is intended to perform basic manta tests ##############
#                                                                            #
#  Author: Mohamed Khalfella <mohamed.khalfella@joyent.com>                  #
#  Purpose: Run the NOC to collect basic info about manta state.             #
#                                                                            #
##############################################################################

echo  -e "\nChecking $MANTA_URL \n"

MURL=$(sed 's@https://@@' <<< $MANTA_URL)


echo 'Checking manta frontend services.......'

for fip in $(dig A +short $MURL @8.8.8.8)
do
	CRES=$(curl -s http://$fip/ping)
	CEXT=$([ $? == "0" -o -n "$CRES" ] && echo OK || echo ERR)
	printf "%16s [%3s]\n" $fip $CEXT
done


## Test putting a dummy file in manta ##
echo -e "\nPushing 1MB of data to manta\n"
DUMMY=/tmp/mnoc_dummy_1mb_file
dd if=/dev/zero bs=1024 count=1024 of=$DUMMY 2>&1 1>/dev/null

time mput  -f $DUMMY ~~/stor/dummy
time mput  -f $DUMMY ~~/stor/dummy
time mput  -f $DUMMY ~~/stor/dummy

TRES="$(sh -c "time -p mput  -f $DUMMY ~~/stor/dummy &> /dev/null" 2>&1)"
TRES=$(cut -f2 -d' ' <<< $TRES)
PSPD=$(echo "scale=2; 1024 / $TRES "| bc)
printf "\nPut speed: %.2f KB/s\n" $PSPD


## Test reading the dummy file back ##
echo -e "\nPulling  1MB of data to manta\n"
time mget ~~/stor/dummy > /dev/null
time mget ~~/stor/dummy > /dev/null
time mget ~~/stor/dummy > /dev/null

TRES="$(sh -c "time -p mget -o ${DUMMY}.o ~~/stor/dummy &> /dev/null" 2>&1)"
TRES=$(cut -f2 -d' ' <<< $TRES)
GSPD=$(echo "scale=2; 1024 / $TRES "| bc)
printf "\nGet speed: %.2f KB/s\n" $GSPD
