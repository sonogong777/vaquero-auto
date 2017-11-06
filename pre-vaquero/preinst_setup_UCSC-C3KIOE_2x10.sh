# vim: ts=4 sw=4
#!/bin/bash

#LOG=/dev/null
LOG=preinstall.out
CURL="curl -s -k -d"
new_class_of_service=-1
controller_list=( "SBMezz1" "IOEMezz1" )
drive_list=( "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28" \
			 "29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56" )

help () {
	echo -e "Preinstallation setup for the CDE6032 with IOE (v1.2)"
	echo -e "   options:"
	echo -e "      -b <ip>        BMC IP address"
	echo -e "      -c <ip>        CIMC IP address"
	echo -e "      -D             Destructive; reset storage system - all data may be removed" 
	echo -e "      -N             Nondestructive; will not modify existing storage configuration" 
	echo -e "      -p <pw>        CIMC password"
	echo -e "      -s <ip>        SIOC IP address"
	echo -e "      -t             Test: Write, but do not execute, the commands to preinst_setup.log"
	echo -e "      -u <user>      CIMC username"
	echo -e "\n   Note: each missing and required parameter will be prompted for"
	exit 0
}

banner () {
	echo -e "\n\e[0;36m$1\e[0m" | tee -a $LOG 1>&2 
}

xmlapi() {
	if [[ ${#1} > 0 ]]; then
		banner "$1"
	fi

	if [ "$3" != "quiet" ]; then
		$X $CURL "$2" https://$cimc_ip/nuova | tee -a $LOG
	else
		$X $CURL "$2" https://$cimc_ip/nuova | tee -a $LOG > /dev/null
	fi
}

xmlapicfg () {
	xmlapi "$1" "<configConfMo cookie='$cimc_session' dn='$2'> <inConfig> $3 </inConfig> </configConfMo>"
}

xmlapicfg_q () {
	xmlapi "$1" "<configConfMo cookie='$cimc_session' dn='$2'> <inConfig> $3 </inConfig> </configConfMo>" "quiet"
}

xmlapicfg_chk () {
	xmlapicfg "$1" "$2" "$3" | grep errorDescr; if [ $? == 0 ]; then error_exit; fi
}

notice () {
	echo -e "\n\e[0;33m  NOTE: $1\e[0m" | tee -a $LOG
}

error () {
	echo -e "\n\e[1;97;41m          \e[0m"
	echo -e   "\e[1;97;41m  ERROR:  \e[0m  \e[1;97;41m$1\e[0m"
	echo -e   "\e[1;97;41m          \e[0m\n"
}

error_exit() {
	error "$1"
	logout_exit
}

logout_exit() {
	xmlapi "Exiting ..." "<aaaLogout cookie='' inCookie='$cimc_session'></aaaLogout>" "quiet"
	exit 1
}

while getopts "b:c:Dhp:s:tu:N" opt
do
	case "$opt" in
		b) _bmc_ip=$OPTARG ;;
		c) cimc_ip=$OPTARG ;;
		D) destructive="yes" ;;
		h) help ;;
		p) pw=$OPTARG ;;
		s) _sioc_ip=$OPTARG ;;
		t) X=echo; test=1; LOG=preinst_setup.log; rm -f $LOG;;
		u) user=$OPTARG ;;
		N) destructive="no" ;;
	esac
done

if [ "$cimc_ip" == "" ]; then 
	read -p "     CIMC IP: " cimc_ip
fi

if [ "$_sioc_ip" == "" ]; then 
	read -p "     SIOC IP: " _sioc_ip
fi

if [ "$_bmc_ip" == "" ]; then 
	read -p "      BMC IP: " _bmc_ip
fi

if [ "$user" == "" ]; then
	read -p "    Username: " user
fi

if [ "$pw" == "" ]; then
	read -s -p "    Password: " pw
	echo ""
fi

bmc_ip=$_bmc_ip
sioc_ip=$_sioc_ip

echo -e "\n\e[0;36mLogging into $cimc_ip:\e[0m"
cimc_session=`$CURL "<aaaLogin inName='$user' inPassword='$pw'></aaaLogin>" https://$cimc_ip/nuova | sed "s/.*outCookie=\"\([0-9a-f\/\-]*\).*/\1/"`

#echo $cimc_session
#exit 0

if [ "$cimc_session" != "" ] && ! grep -q "[g-zG-Z]" <<< "$cimc_session"; then
	server_node=(`$CURL "<configResolveClass cookie='$cimc_session' classId='computeServerNode' inHierarchical='false'></configResolveClass>" \
				  https://$cimc_ip/nuova  |  grep -o serverId=\"[0-9]\" | grep -o "[0-9]"`)

	num_server_nodes=${#server_node[@]}

# Some sanity checks

	if [ $num_server_nodes != 1 ]; then
		error_exit "CIMC reports an unexpected number of server nodes ($num_server_nodes)"
	fi

	if [ "$destructive" == ""  ]; then
		notice "Continuing may cause all data on this system to be removed."
		echo ""

		read -p "Continue [N/y]? " proceed

		if [ "$proceed" == "y" ]; then
			destructive="yes"
		else
			echo -e "\nUse the -N option to perform a nondestructive setup.\n"
			logout_exit
		fi
	fi

#
# If destructive is enabled then configure drive allocations
#

	if [ "$destructive" == "yes" ]; then
		vd_list=( `$CURL \
			      "<configResolveClass cookie='$cimc_session' classId='storageVirtualDrive' inHierarchical='false'/>"  \
				   https://$cimc_ip/nuova | grep -oP '(?<=dn=\").+?(?=\")'` )

# Remove boot drive status

		for c in ${controller_list[@]}; do 
			xmlapicfg_chk "Removing boot drive status from sys/chassis-1/server-2/board/storage-SAS-$c" \
						  "sys/chassis-1/server-2/board/storage-SAS-$c" \
						  "<storageController adminAction='clear-boot-drive'/>"
		done

# Delete existing virtual drives 

		for (( i=0; i<${#vd_list[@]}; i++ )); do
			xmlapicfg_chk "Deleting virtual drive: ${vd_list[$i]}" \
				  	      "${vd_list[$i]}" \
				  	      "<storageVirtualDrive status='deleted'/>"
		done

		if [ "$test" != "1" ]; then sleep 3; fi

# Learn which storage class to use for storage related commands

        $CURL "<configResolveDn cookie='$cimc_session' inHierarchical='false' dn='sys/chassis-1/enc-1/zone-drive'/>" https://$cimc_ip/nuova | grep -q Enclosure

        if [ "$?" == "0" ]; then
			class=("enc-1" "Enclosure")
		else
			class=("storage" "Chassis")
		fi

# Unassign all drives

		xmlapicfg_q "Unassigning all drives:" \
			  	    "sys/chassis-1/${class[0]}/zone-drive" \
			  	    "<storage${class[1]}DiskSlotZoneHelper \
				  	  dn='sys/chassis-1/${class[0]}/zone-drive' \
					  slotList='${drive_list[0]},${drive_list[1]}' \
					  ownership='none' \
					  adminState='trigger'/>"

		for (( i=0; i<2; i++ )); do

# Assign drives to nodes; ensure the correct set of drives always goes to the correct server node

			xmlapicfg_chk "Assigning drives ${drive_list[$i]} to sys/chassis-1/server-$server_node/${controller_list[$i]}:" \
				          "sys/chassis-1/${class[0]}/zone-drive" \
				          "<storage${class[1]}DiskSlotZoneHelper \
							dn='sys/chassis-1/${class[0]}/zone-drive' \
							slotList='${drive_list[$i]}' \
							ownership='server$server_node' \
							ownershipController='${controller_list[$i]}' \
							adminState='trigger'/>"
		done
	fi

#
# Configure each nodes network settings
#

# Determine the proper network class

    $CURL "<configResolveDn cookie='$cimc_session' inHierarchical='false' dn='sys/chassis-1/server-2/adaptor-SIOC2'/>" https://$cimc_ip/nuova | grep -q "id="

    if [ "$?" == "0" ]; then
		sioc="SIOC"
	else
		sioc=""
	fi

# Reset the SIOC to facory defaults

	notice "The following reset command may take a couple minutes to complete."

	xmlapicfg_chk "Resetting to defaults sys/chassis-1/server-$server_node/adaptor-${sioc}$server_node:" \
				  "sys/chassis-1/server-$server_node/adaptor-${sioc}$server_node" \
				  "<adaptorUnit \
						id='${sioc}$server_node' \
						adminState='adaptor-reset-default' \
						dn='sys/chassis-1/server-$server_node/adaptor-${sioc}$server_node'> \
				   </adaptorUnit>"

	if [ "$test" != "1" ]; then sleep 30; fi

# Configure each node's mgmtif

	if [ "$generic" != "yes" ]; then
		if [ "$bmc_ip" != "" ]; then
			xmlapicfg_chk "Setting sys/chassis-1/server-$server_node/mgmt/if-1 network:" \
						  "sys/chassis-1/server-$server_node/mgmt/if-1" \
						  "<mgmtIf \
								dn='sys/chassis-1/server-$server_node/mgmt/if-1' \
								v4IPAddr='$bmc_ip'> \
						   </mgmtIf>"
		else
			notice "Skipping sys/chassis-1/server-$server_node/mgmt/if-1 network setup."
		fi

		if [ "$sioc_ip" != "" ]; then
			xmlapicfg_chk "Setting sys/chassis-1/slot-$server_node/mgmt/if-1 network:" \
						  "sys/chassis-1/slot-$server_node/mgmt/if-1" \
						  "<mgmtIf \
								dn='sys/chassis-1/slot-$server_node/mgmt/if-1' \
								v4IPAddr='$sioc_ip'> \
						   </mgmtIf>"
		else
			notice "Skipping sys/chassis-1/slot-$server_node/mgmt/if-1 network setup."
		fi
	fi

# Configure the data vNICs

	for (( eth_num=0; eth_num<2; eth_num++ )); do
		xmlapicfg_chk "Configuring element 'sys/chassis-1/server-$server_node/adaptor-$sioc$server_node/host-eth-eth${eth_num}':" \
					  "sys/chassis-1/server-$server_node/adaptor-$sioc$server_node/host-eth-eth$eth_num" \
					  "<adaptorHostEthIf \
								dn='sys/chassis-1/server-$server_node/adaptor-$sioc$server_node/host-eth-eth$eth_num' \
								name='eth$eth_num' \
								mac='AUTO' \
								mtu='8192' \
								pxeBoot='disabled' \
								status='modified'> \
							<adaptorEthInterruptProfile rn='eth-int' count='18' coalescingTime='0'/> \
							<adaptorEthRecvQueueProfile rn='eth-rcv-q' count='8' ringSize='4096'/> \
							<adaptorEthWorkQueueProfile rn='eth-work-q' count='8' ringSize='4096'/> \
							<adaptorEthCompQueueProfile rn='eth-comp-q' count='16' /> \
							<adaptorEthOffloadProfile rn='eth-offload'/> \
							<adaptorIpV4RssHashProfile rn='ipv4-rss-hash'/> \
							<adaptorExtIpV6RssHashProfile rn='ext-ipv6-rss-hash'/> \
							<adaptorIpV6RssHashProfile rn='ipv6-rss-hash'/> \
							<adaptorRssProfile rn='rss' receiveSideScaling='enabled' /> \
					   </adaptorHostEthIf>"
	done

# Set the boot device order

	$CURL "<configResolveDn cookie='$cimc_session' inHierarchical='false' dn='sys/chassis-1/server-2/equipped-slot-SBMezz1'/>" \
		https://$cimc_ip/nuova | grep -q "C3000 RAID"

    if [ "$?" == "0" ]; then
		xmlapicfg_chk "Setting boot device order on 'sys/chassis-1/server-$server_node':" \
					  "sys/chassis-1/server-$server_node/boot-precision" \
					  "<lsbootDevPrecision \
							dn='sys/chassis-1/server-$server_node/boot-precision' rebootOnUpdate='no' reapply='yes'> \
						   	<lsbootUsb name='usbcd' type='USB' subtype='usb-cd' order='1' state='Enabled' rn='usb-usbcd'/> \
						   	<lsbootVMedia name='vMedia' type='VMEDIA' subtype='cimc-mapped-dvd' order='2' state='Enabled' rn='vm-vMedia'/> \
						   	<lsbootHdd name='system' type='LOCALHDD' slot='SBMezz1' order='3' state='Enabled' rn='hdd-system'/> \
							<lsbootPxe name='network1' type='PXE' slot='SIOC$server_node' port='0' order='4' state='Enabled' rn='pxe-network1'/> \
							<lsbootPxe name='network2' type='PXE' slot='SIOC$server_node' port='1' order='5' state='Enabled' rn='pxe-network2'/> \
					 </lsbootDevPrecision>"
	else
		xmlapicfg_chk "Setting PCH boot device order on 'sys/chassis-1/server-$server_node':" \
					  "sys/chassis-1/server-$server_node/boot-precision" \
					  "<lsbootDevPrecision \
							dn='sys/chassis-1/server-$server_node/boot-precision' rebootOnUpdate='no' reapply='yes'> \
						   	<lsbootPchStorage name='system0' type='PCHSTORAGE' lun='0' order='1' state='Enabled' rn='pchstorage-system0'/> \
							<lsbootPchStorage name='system1' type='PCHSTORAGE' lun='1' order='2' state='Enabled' rn='pchstorage-system1'/> \
							<lsbootPxe name='pxe' type='PXE' slot='$server_node' port='1' order='3' state='Enabled' rn='pxe-pxe'/> \
					 </lsbootDevPrecision>"
	fi

# Adjust BIOS Settings

	xmlapicfg_chk "Disabling HyperThreading on sys/chassis-1/server-$server_node:" \
				  "sys/chassis-1/server-$server_node/bios/bios-settings/Intel-HyperThreading-Tech" \
				  "<biosVfIntelHyperThreadingTech \
						dn='sys/chassis-1/server-$server_node/bios/bios-settings/Intel-HyperThreading-Tech' \
						vpIntelHyperThreadingTech='disabled'> \
				   </biosVfIntelHyperThreadingTech>"

	xmlapicfg_chk "Disabling Power Management on sys/chassis-1/server-$server_node:" \
				  "sys/chassis-1/server-$server_node/bios/bios-settings/CPU-PowerManagement" \
				  "<biosVfCPUPowerManagement \
						dn='sys/chassis-1/server-$server_node/bios/bios-settings/CPU-PowerManagement' \
						vpCPUPowerManagement='disabled'> \
				   </biosVfCPUPowerManagement>"

	xmlapicfg_chk "Disabling Virtualization Technology on sys/chassis-1/server-$server_node:" \
				  "sys/chassis-1/server-$server_node/bios/bios-settings/Intel-Virtualization-Technology" \
				  "<biosVfIntelVirtualizationTechnology \
						dn='sys/chassis-1/server-$server_node/bios/bios-settings/Intel-Virtualization-Technology' \
						vpIntelVirtualizationTechnology='disabled'> \
				   </biosVfIntelVirtualizationTechnology>"

# Reset the adaptor again, without defaults, to apply the changes

	xmlapicfg_chk "Resetting to apply changes to sys/chassis-1/server-$server_node/adaptor-${sioc}$server_node:" \
				  "sys/chassis-1/server-$server_node/adaptor-${sioc}$server_node" \
				  "<adaptorUnit \
						id='${sioc}$server_node' \
						adminState='adaptor-reset' \
						dn='sys/chassis-1/server-$server_node/adaptor-${sioc}$server_node'> \
				   </adaptorUnit>"


	if [ "$test" != "1" ]; then sleep 30; fi

	if [ "$LOG" != "/dev/null" ]; then
		sed -i -e 's/\t//g' -e 's/ [ ]*/ /g' $LOG 
	fi

	echo -e "\n\e[0;36mLogging out of $cimc_ip:\e[0m"
    $CURL "<aaaLogout cookie='' inCookie='$cimc_session'></aaaLogout>" https://$cimc_ip/nuova > /dev/null
else
	error "Failed to establish CIMC session!  Please check IP address, username, and password."
fi

