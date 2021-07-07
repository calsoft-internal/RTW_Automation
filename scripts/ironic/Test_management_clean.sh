#!/bin/bash
TEST_CASE_NAME="Test iDRAC driver WS-Man management cleaning step"

if [ $# -ne 1 ]; then
    echo
    echo "WARNING: Usage: Test_iDRAC_driver_WS-Man_management_clean.sh <NODE_UUID>"
    echo
    exit 1
fi

NODE_UUID=$1

echo "INFO: NODE UUID is: $NODE_UUID"

. ~/devstack/openrc admin

set -x

echo "INFO: Checking node existence"
result=$(openstack baremetal node show $NODE_UUID -c 'uuid' -f value)
if [ -z "$result" ]
then
        echo "ERROR: Node is not present or invalid node uuid has been provided "
        exit 1
else
        echo "INFO: Preparing node for cleaning step"
fi

echo "INFO: Checking node provision_state"
provision_state=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
if [ $provision_state == 'manageable' ]
then
        echo "INFO: Node provision_state is ${provision_state}"
else
        echo "ERROR: Current state of node is ${provision_state}, it should be in manageable state"
        exit 1
fi
echo "INFO: Checking node management_interface"
current_interface=$(openstack baremetal node show $NODE_UUID -c "management_interface" -f value)
if [ $current_interface == 'idrac-wsman' ]
then
        echo "INFO: Node management_interface is ${current_interface}"
else
        echo "ERROR: Invalid Node management_interface"
        exit 1
fi

echo "INFO: Starting reset_idrac cleaning steps"
openstack baremetal node clean --clean-steps '[{ "interface" : "management" , "step" : "reset_idrac"}]' $NODE_UUID

while :
do
        clean_result=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
        if [ $clean_result == 'manageable' ]
        then
                echo "INFO: iDRAC reset completed successfully"
                break
        elif [ $clean_result == "clean failed" ]
        then
                echo "ERROR: Node cleaning  failed"
                openstack baremetal node show $NODE_UUID | grep last_error
                exit 1
        else
                echo "INFO: Node is in clean wait  state for reset_idrac scenario"

        fi

done

echo "INFO: Checking node provision_state"
provision_state=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
if [ $provision_state == 'manageable' ]
then
        echo "INFO: Node provision_state is ${provision_state}"
else
        echo "ERROR: Current state of node is ${provision_state}, it should be in manageable state"
        exit 1
fi

echo "INFO: Starting clear_job_queue cleaning steps"
openstack baremetal node clean --clean-steps '[{ "interface" : "management" , "step" : "clear_job_queue"}]' $NODE_UUID

while :
do
        clean_result=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
        if [ $clean_result == 'manageable' ]
        then
                echo "INFO: iDRAC clear_job_queue completed successfully"
                break
        elif [ $clean_result == "clean failed" ]
        then
                echo "ERROR: Node cleaning  failed"
                openstack baremetal node show $NODE_UUID | grep last_error
                exit 1
        else
                echo "INFO: Node is in clean wait  state for clear_job_queue scenario"

        fi

done

echo "INFO: Checking node provision_state"
provision_state=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
if [ $provision_state == 'manageable' ]
then
        echo "INFO: Node provision_state is ${provision_state}"
else
        echo "ERROR: Current state of node is ${provision_state}, it should be in manageable state"
        exit 1
fi

echo "INFO: Starting known_good_state cleaning steps"
openstack baremetal node clean --clean-steps '[{ "interface" : "management" , "step" : "known_good_state"}]' $NODE_UUID

while :
do
        clean_result=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
        if [ $clean_result == 'manageable' ]
        then
                echo "INFO: iDRAC known_good_state completed successfully"
                break
        elif [ $clean_result == "clean failed" ]
        then
                echo "ERROR: Node cleaning  failed"
                openstack baremetal node show $NODE_UUID | grep last_error
                exit 1
        else
                echo "INFO: Node is in clean wait state for known_good_state scenario "

        fi

done
