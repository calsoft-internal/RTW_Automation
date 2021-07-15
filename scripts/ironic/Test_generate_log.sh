#! /bin/bash
Now=$(date "+%Y.%m.%d-%H.%M.%S")

function start_ironic_cond_logs()
{
sudo journalctl -f -u devstack@ir-cond.service > Test_Wsman_Inspect.log-$Now 2>&1 &

filename=`ls /opt/stack| grep "Test_Wsman_Inspect.log-"$Now`
echo "Generated Log File is : "$filename
}

function stop_ironic_cond_logs()
{
check=`openstack baremetal node list | egrep -c 'manageable|inspect failed'`
if [ ${check} == 1 ]
then
        echo 'stopping condouctor log'
        sudo pkill -f devstack@ir-cond.service
else
        stop_ironic_cond_logs

fi

}
start_ironic_cond_logs
stop_ironic_cond_logs
