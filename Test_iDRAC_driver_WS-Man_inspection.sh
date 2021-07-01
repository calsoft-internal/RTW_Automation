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
        echo "ERRRO: Node is not present or provided invalid node uuid "
        exit 1
else
        echo "INFO: Preparing node for inspection"
fi

echo "INFO: Checking node provision_state"
state=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
if [ $state == 'manageable' ]
then
        echo "INFO: Node provision_state is ${state}"
        #start_inspection=$(openstack baremetal node inspect $NODE_UUID)
else
	echo "ERROR: Invalid Node provision_state it should be manageable"
	exit 1
fi
echo "INFO: Checking node inspect_interface"
current_interface=$(openstack baremetal node show $NODE_UUID -c "inspect_interface" -f value)
if [ $current_interface == 'idrac-wsman' ]
then
        echo "INFO: Node inspect_interface is ${current_interface}"
else
        echo "ERROR: Invalid Node inspect_interface"
        exit 1
fi
#todo use while loop and add inspect failed condition 

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
		echo "ERROR: Node inspection failed "
		exit 1
	else
		echo "INFO: Node is in inspecting state"

	fi
	
done

echo "INFO: Checking created baremetal port list"
port_list=$(openstack baremetal port list --node $NODE_UUID -c 'UUID' -f value)
if [ -z "$port_list" ]
then
        echo "WARNING: Node dosent have any baremetal port created "
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

#openstack baremetal port list --node b6f2ec86-4160-4fce-86dd-c9c4ded6148c -c 'UUID' -f value
#openstack baremetal port list --node b6f2ec86-4160-4fce-86dd-c9c4ded6148c
#true=openstack baremetal port show f63b4a44-1453-469f-bfef-47fac0cc6e29 -c 'pxe_enabled' -f value
