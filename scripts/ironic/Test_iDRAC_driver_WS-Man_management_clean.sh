#!/bin/bash
TEST_CASE_NAME="Test iDRAC driver WS-Man management cleaning step"

if [ $# -ne 2 ]; then
    echo
    echo "WARNING: Usage: Test_iDRAC_driver_WS-Man_management_clean.sh <NODE_UUID> <Required_step>"
    echo
    exit 1
fi

NODE_UUID=$1
Required_step=$2



echo "INFO: NODE UUID is: $NODE_UUID"

. ~/devstack/openrc admin

set -x

echo "INFO: Checking node existence"
result=$(openstack baremetal node show $NODE_UUID -c 'uuid' -f value)
if [ -z "$result" ]
then
        echo "ERROR: Node is not present or invalid node UUID has been provided ${NODE_UUID}"
        exit 1
else
        echo "INFO: Preparing ${NODE_UUID} node for cleaning step"
fi

echo "INFO: Checking node provision_state"
provision_state=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
if [ $provision_state == 'manageable' ]
then
        echo "INFO: Node provision_state is ${provision_state}"
else
	echo "ERROR: Invalid ${provision_state} provision_state for ${NODE_UUID} it should be manageable"
	exit 1
fi
echo "INFO: Checking node management_interface"
current_interface=$(openstack baremetal node show $NODE_UUID -c "management_interface" -f value)
if [ $current_interface == 'idrac-wsman' ]
then
        echo "INFO: Node management_interface is ${current_interface}"
else
        echo "ERROR: Invalid ${current_interface} management_interface set for ${NODE_UUID}"
        exit 1
fi

echo "INFO: Starting management cleaning steps"
openstack baremetal node clean --clean-steps '[{ "interface" : "management","step" :"'$Required_step'"}]' $NODE_UUID

while :
do
	clean_result=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
	sleep 120
	if [ $clean_result == 'manageable' ]
	then
		echo "INFO: $Required_step completed successfully"
		break
	elif [ $clean_result == 'clean failed']
	then
		echo "ERROR: Node cleaning  failed for $Required_step"
		error_msg=$(openstack baremetal node show $NODE_UUID -c last_err -f value)
		echo "ERROR: Node clean failed due to ${error_msg}"
		exit 1
	else
		echo "INFO: Node is in $clean_result state for $Required_step"

	fi

done