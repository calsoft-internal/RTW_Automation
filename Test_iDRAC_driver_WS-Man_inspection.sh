#!/bin/bash
TEST_CASE_NAME="Test iDRAC driver WS-Man inspection (idrac-wsman)"

if [ $# -ne 1 ]; then
    echo
    echo "WARNING: Usage: Test_iDRAC_driver_WS-Man_inspection (idrac-wsman).sh <NODE_UUID>"
    echo
    exit 1
fi

NODE_UUID=$1

echo "INFO: NODE UUID is: $NODE_UUID"

. ~/devstack/openrc admin

set -x

echo "INFO: Checking node existance"
result=$(openstack baremetal node show $NODE_UUID -c 'uuid' -f value)
if [ -z "$result" ]
then
        echo "ERROR: Node is not present or provided invalid ${NODE_UUID}"
        exit 1
else
        echo "INFO: Preparing ${NODE_UUID} node for inspection"
fi

echo "INFO: Checking node provision_state"
provision_state=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
echo "INFO : Current provision_state for ${NODE_UUID}  is ${provision_state}"

if [ $provision_state == 'manageable' ]
then
        echo "INFO: Node provision_state is ${provision_state}"
else
	echo "ERROR: Invalid ${provision_state} provision_state for ${NODE_UUID} it should be manageable"
	exit 1
fi

echo "INFO: Checking node inspect_interface"
current_interface=$(openstack baremetal node show $NODE_UUID -c "inspect_interface" -f value)
echo "INFO : Current inspect_interface for ${NODE_UUID}  is ${current_interface}"

if [ $current_interface == 'idrac-wsman' ]
then
        echo "INFO: Node inspect_interface is ${current_interface}"
else
        echo "ERROR: Invalid ${current_interface} inspect_interface set for ${NODE_UUID}"
        exit 1
fi

echo "INFO: Starting ws-man inspection"
openstack baremetal node inspect $NODE_UUID

while :
do
	inspection_result=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
	if [ $inspection_result == 'manageable' ]
	then
		echo "INFO: iDRAC driver WS-Man inspection successfully"
		break
	elif [ $inspection_result == "inspect failed" ]
	then
		error_msg=$(openstack baremetal node show $NODE_UUID -c last_err -f value)
		echo "ERROR: Node inspection failed due to ${error_msg}"
		exit 1
	else
		echo "INFO: Node is in ${inspection_result} state"

	fi
	
done

echo "INFO: Checking baremetal port list"
port_list=$(openstack baremetal port list --node $NODE_UUID -c 'UUID' -f value)

if [ -z "$port_list" ]
then
        echo "WARNING: Baremetal port not found for ${NODE_UUID} "
else
	echo "INFO: list of created baremetal port list is ${port_list}"
	echo "INFO: Checking baremetal port pxe_enabled status"
	array=($port_list)
	for i in "${array[@]}"
	do
		pxe_enabled_status=$(openstack baremetal port show ${i} -c 'pxe_enabled' -f value)
		if [ $pxe_enabled_status == 'True' ]
		then
			echo "INFO: Baremetal port ${i} is set for True"
		else
			echo "INFO: Baremetal port ${i} is set for False"
		fi
	done
fi

