#! /bin/bash
. ~/devstack/openrc admin
if [ $# -ne 3 ]; then
    echo
    echo "Usage:Test discover noder <IP> <UN> <P>"
    echo
    exit 1
fi
<<<<<<< HEAD
=======

>>>>>>> 46d82c0db9aadebc96740d7cf20eb26d1d6f5a47
pm_addr=$1
pm_user=$2
pm_password=$3
Now=$(date "+%Y.%m.%d-%H.%M.%S")
function dicover_node(){
    if [[ $pm_addr =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        wsman enumerate http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/root/dcim/DCIM_SystemView   -h $pm_addr -V -v -c dummy.cert -P         443 -u $pm_user -p $pm_password -j utf-8 -y basic > node_info-$Now 2>&1 &
        filename=`ls /opt/stack| grep "node_info-"$Now`
        echo "Node Info File is : "$filename
        sleep 6
        Model=`cat node_info-$Now| grep -oP '(?<=n1:Model>).*(?=</n1:Model)'`
        echo "Server Model is: "$Model
        ServiceTag=`cat node_info-$Now | grep -oP '(?<=n1:ServiceTag>).*(?=</n1:ServiceTag)'`
        echo "ServiceTag is : " $ServiceTag
        echo "pm_addr is : " $pm_addr
        echo "pm_user is : " $pm_user
        echo "pm_password is : " $pm_password
    else
        echo "Please Provide correct IP"
    fi
}

dicover_node
