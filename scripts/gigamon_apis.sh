#!/bin/bash
rg_name=$1
vnet_id=$2
subnet1_name=$4
subnet2_name=$5
nsg_name=$6
nsg_id=$7
region=$8
ip=$9
ntopng_ip=${10}
sec_onion_ip=${11}
password=${12}

conn_data="{\"id\": \"\",  \"alias\": \"azure\",\"regionName\": \"$region\",\"authType\": \"managedServiceIdentity\",\"virtualNetworkId\": \"$vnet_id\" }"
curl  --insecure  -X POST https://localhost/api/v1.3/vfm/azure/connections  -u admin:admin123A!  -d "$conn_data" --header "Content-Type:application/json"
sleep 10
d=`curl -s --insecure -u admin:admin123A! 'https://localhost/api/v1.3/vfm/azure/connections' | grep '"id" :'| cut -d ":" -f2 | tr -d "\"," | tr -d " "`

data="{\"id\" : \"\",\"connAlias\" : \"azure\", \"connId\" : \"$d\",\"mtu\" : 1450,\"agentTunnelType\" : \"vxlan\",\"usePublicIps\" : false,\"diskType\" : \"SSD\",\"authenticationType\" : \"password\",\"password\": \"$password\",\"resourceGroupName\" : \"$rg_name\",\"virtualNetworkId\" : \"$vnet_id\",\"fabricNodeConfigs\" : [ {  \"imageId\" : \"${g-vtap_image_id}\", \"imageName\" : \"${g-vtap_image_name}\", \"size\" : \"Standard_DS1_v2\", \"numOfInstancesToLaunch\" : 1} ],\"mgmtSubnetSpec\" : {  \"subnetId\" : \"$vnet_id/subnets/$subnet1_name\",  \"subnetName\" : \"$subnet1_name\", \"acceleratedNetworking\" : false, \"networkSecurityGroups\" : [ { \"networkSecurityGroupId\" : \"$nsg_id\", \"networkSecurityGroupName\" : \"$nsg_name\" }]}}"

curl  --insecure -X POST https://localhost/api/v1.3/vfm/azure/fabricDeployment/gvTapControllers/configs  -u admin:admin123A! -d "$data" --header "Content-Type:application/json"
sleep 3
data1="{ \"id\": \"\",    \"connAlias\": \"azure\", \"connId\": \"$d\", \"usePublicIps\": false, \"diskType\": \"SSD\", \"authenticationType\": \"password\", \"password\": \"$password\", \"resourceGroupName\": \"$rg_name\", \"size\": \"Standard_DS1_v2\", \"imageId\": \"${vseries-cntlr_image_id}\", \"imageName\": \"${vseries-cntlr_image_name}\", \"virtualNetworkId\": \"$vnet_id\", \"mgmtSubnetSpec\": { \"subnetId\": \"$vnet_id/subnets/$subnet1_name\", \"subnetName\": \"$subnet1_name\", \"acceleratedNetworking\": false, \"networkSecurityGroups\": [ { \"networkSecurityGroupId\": \"$nsg_id\", \"networkSecurityGroupName\": \"$nsg_name\" }]},\"numOfInstancesToLaunch\": 1}"

curl  --insecure -X POST https://localhost/api/v1.3/vfm/azure/fabricDeployment/vseriesControllers/configs  -u admin:admin123A! -d "$data1"  --header "Content-Type:application/json"
sleep 180
data2="{\"id\": \"\",\"connAlias\": \"azure\",\"connId\": \"$d\",\"mtu\": 1450,\"diskType\": \"SSD\",\"authenticationType\": \"password\",\"password\": \"$password\",\"resourceGroupName\": \"$rg_name\",\"size\": \"Standard_B2s\",\"maxInstancesToLaunch\": 1,\"minInstancesToLaunch\": 1,\"imageId\": \"${vseries-node_image_id}\",\"imageName\": \"${vseries-node_image_name}\",\"virtualNetworkId\": \"$vnet_id\",\"mgmtSubnetSpec\": {  \"subnetId\": \"$vnet_id/subnets/$subnet1_name\",  \"subnetName\": \"$subnet1_name\",  \"acceleratedNetworking\": false,  \"networkSecurityGroups\": [{\"networkSecurityGroupId\": \"$nsg_id\", \"networkSecurityGroupName\": \"$nsg_name\"}]},\"dataSubnetsSpec\":[{\"subnetId\": \"$vnet_id/subnets/$subnet1_name\", \"subnetName\": \"$subnet1_name\", \"acceleratedNetworking\": false,\"networkSecurityGroups\": [{ \"networkSecurityGroupId\": \"$nsg_id\", \"networkSecurityGroupName\": \"$nsg_name\" }] },{\"subnetId\": \"$vnet_id/subnets/$subnet2_name\", \"subnetName\": \"$subnet2_name\", \"acceleratedNetworking\": false,\"networkSecurityGroups\": [{ \"networkSecurityGroupId\": \"$nsg_id\",  \"networkSecurityGroupName\": \"$nsg_name\" } ]}] }"

curl  --insecure -X POST https://localhost/api/v1.3/vfm/azure/fabricDeployment/vseriesNodes/configs  -u admin:admin123A! -d "$data2"  --header "Content-Type:application/json"

tunnel1="{\"type\": \"vxlan\",\"vxlanConfig\": {\"id\": \"1\", \"alias\": \"secOnion\",\"dstAddress\": \"$sec_onion_ip\",\"dstPort\": \"4789\",\"trafficDirection\": \"out\",\"nodeIfaceSubnetCIDR\": \"\" }}"
curl --insecure -X POST https://localhost/api/v1.3/vfm/tunnelSpecs -u admin:admin123A! -d "$tunnel1" --header "Content-Type:application/json"

tunnel2="{\"type\": \"vxlan\",\"vxlanConfig\": {\"id\": \"2\", \"alias\": \"NtopNg\",\"dstAddress\": \"$ntopng_ip\",\"dstPort\": \"4789\",\"trafficDirection\": \"out\",\"nodeIfaceSubnetCIDR\": \"\" }}"
curl --insecure -X POST https://localhost/api/v1.3/vfm/tunnelSpecs -u admin:admin123A! -d "$tunnel2" --header "Content-Type:application/json"

monitoring_session="{ \"alias\": \"Session1\",\"id\": \"1\",\"connId\": \"${d}\", \"connAlias\": \"azure\", \"deployed\": false }"

curl  --insecure  -X POST https://localhost/api/v1.3/vfm/monitoringSessions -u admin:admin123A! -d "$monitoring_session" --header "Content-Type:application/json"

curl --insecure -X POST https://localhost/api/v1.3/vfm/maps -u admin:admin123A! -d '{ "id": "1", "alias": "passall", "rules":[ {"actionSet": 0,"comment": "", "filters": [], "priority": 0 }] }' --header "Content-Type:application/json"
curl --insecure -X POST https://localhost/api/v1.3/vfm/maps -u admin:admin123A! -d '{ "id": "2", "alias": "http","rules": [{"actionSet": 0, "filters": [{ "type": "etherType", "value": "0x0800"},{"type": "ipProto","value": 6 },{ "type": "portDst", "valueMax": 80, "value": 0 }],"priority": 0}] }]}' --header "Content-Type:application/json"
curl --insecure -X POST https://localhost/api/v1.3/vfm/maps -u admin:admin123A! -d '{ "id": "3", "alias": "icmp","rules": [{"actionSet": 0, "filters": [{ "type": "etherType", "value": "0x0800"},{"type": "ipProto","value": 1 }],"priority": 0}] }]}' --header "Content-Type:application/json"
