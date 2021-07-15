#!/bin/bash
TEST_CASE_NAME="Test iDRAC driver redfish management cleaning step"

if [ $# -ne 2 ]; then
    echo
    echo "WARNING: Usage: Test_iDRAC_driver_redfish_management_clean.sh <NODE_UUID> <clean_step>.The valid clean steps are- reset_idrac,known_good_state,clear_job_queue"
    echo
    exit 1
fi

NODE_UUID=$1
clean_step=$2

echo "INFO: NODE UUID is: $NODE_UUID"

. ~/devstack/openrc admin

set -x

echo "INFO: Checking node existence"
node_uuid=$(openstack baremetal node show $NODE_UUID -c 'uuid' -f value)
if [ -z "$node_uuid" ]
then
        echo "ERROR: Node ${NODE_UUID} is not present or invalid node UUID has been provided "
        exit 1
else
        echo "INFO: Preparing node ${NODE_UUID} for cleaning step"
fi

echo "INFO: Checking node provision_state"
provision_state=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
if [ $provision_state == 'manageable' ]
then
        echo "INFO: Node ${NODE_UUID} provision_state is ${provision_state}"
else
	echo "ERROR: Invalid ${provision_state} provision_state for node ${NODE_UUID} it should be manageable"
	exit 1
fi

echo "INFO: Checking node management_interface"
current_interface=$(openstack baremetal node show $NODE_UUID -c "management_interface" -f value)
if [ $current_interface == 'idrac-redfish' ]
then
        echo "INFO: Node ${NODE_UUID} management_interface is ${current_interface}"
else
        echo "ERROR: Invalid ${current_interface} management_interface set for node ${NODE_UUID}"
        exit 1
fi

Now=$(date "+%Y.%m.%d-%H.%M.%S")

function start_ironic_cond_logs()
{
sudo journalctl -f -u devstack@ir-cond.service > Test_iDRAC_driver_redfish_management_clean_$clean_step-$Now 2>&1 &

#filename=`ls /opt/stack/sagar_automation| grep "Test_iDRAC_driver_redfish_management_clean_$clean_step-"$Now`
#echo "Generated Log File is : "$filename
}
start_ironic_cond_logs

echo "INFO: Starting $clean_step cleaning step"
openstack baremetal node clean --clean-steps '[{ "interface" : "management","step" :"'$clean_step'"}]' $NODE_UUID
while :
do
	clean_result=$(openstack baremetal node show $NODE_UUID -c provision_state -f value)
	
	if [ "$clean_result" == "manageable" ]
	then
		echo "INFO: $clean_step completed successfully"
		break
	elif [ "$clean_result" == "clean failed" ]
	then
		echo "ERROR:$clean_step clean step failed for node $NODE_UUID"
		error_msg=$(openstack baremetal node show $NODE_UUID -c last_err -f value)
		echo "ERROR: Node clean failed due to ${error_msg}"
		exit 1
	else
		echo "INFO: Node is in $clean_result state for $clean_step"
                sleep 60

	fi
done

function stop_ironic_cond_logs()
{
check=`openstack baremetal node list | egrep -c 'manageable|clean failed'`
if [ ${check} == 1 ]
then
        echo 'stopping condouctor log'
        sudo pkill -f devstack@ir-cond.service
else
        stop_ironic_cond_logs

fi

}
stop_ironic_cond_logs
filename=`ls /opt/stack/sagar_automation| grep "Test_iDRAC_driver_redfish_management_clean_$clean_step-"$Now`
echo "Generated Log File is : "$filename


