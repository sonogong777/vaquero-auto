#!/bin/bash
#
# Auto-vaquero deployement..
# attempting for zero touch deployement of COS baremetal..
# version = 5.2
# Cisco AS Services, kerhee@cisco.com
#
# 1.0 basic error check implemented with session limit
# 2.0 use default ip for sioc and bmc if none is provided for cos3260
# 5.0 csvfile validation,inventory file update integrated with pre-vaquero
#     Need post confirmation step prior to removal entry in inventory file.
# 5.1 added checks for bmc and sioc address during input validation.
# 5.2 Defects for duplicate check to be more precise..
#
#######################################################################
csvfile=$1
preinstall="./preinst_setup_UCSC-C3KIOE_2x10.sh"
default_ip="1.1.1.1"
IFS=,
inventory="inventory.yml"
ulimit -u 50

#remove
unset http_proxy https_proxy

#environment data,possibly pulled from env.yaml
cos3260_subnet="3260-subnet"
cos3260_workflow="cos3260-wf"
cos465_subnet="3260-subnet"
cos465_workflow="cos465-wf"
cmc_subnet="vlan-342"
cmc_workflow="cmc-wf"

#templates
templates(){
cos465_template=$(cat  << EOF
name: $cos465_name
interfaces:
  - type: physical
    subnet: $cos465_subnet
    mac: $cos465_mac
    ipv4: $cos465_mgmt_ip
metadata:
    HostName: $cos465_name
    Mgmt_IP: $cos465_mgmt_ip
    Data_eth4_IP: $cos465_Data_eth4
    Data_eth5_IP: $cos465_Data_eth5
workflow: $cos465_workflow
---

EOF
)

cos3260_template=$(cat  << EOF
name: $cos3260_name
interfaces:
  - type: physical
    subnet: $cos3260_subnet
    mac: $cos3260_mac
    ipv4: $cos3260_mgmt_ip
metadata:
    HostName: $cos3260_name
    Mgmt_IP: $cos3260_mgmt_ip
    Data_eth2_IP: $cos3260_Data_eth2
    Data_eth3_IP: $cos3260_Data_eth3
workflow: $cos3260_workflow
---

EOF
)

cmc_template=$(cat  << EOF
name: $cmc_name
interfaces:
  - type: physical
    subnet: $cmc_subnet
    mac: $cmc_mac
    ipv4: $cmc_mgmt_ip
metadata:
    HostName: $cmc_name
    MgmtIP: $cmc_mgmt_ip
workflow: $cmc_workflow
---

EOF
)
}
#template END section


##color
normal=$'\e[0m'                           #
bold=$(tput bold)                         # make colors bold/bright
red="$bold$(tput setaf 1)"                # bright red text
green=$(tput setaf 2)                     # dim green text
fawn=$(tput setaf 3); beige="$fawn"       # dark yellow text
yellow="$bold$fawn"                       # bright yellow text
darkblue=$(tput setaf 4)                  # dim blue text
blue="$bold$darkblue"                     # bright blue text
purple=$(tput setaf 5); magenta="$purple" # magenta text
pink="$bold$purple"                       # bright magenta text
darkcyan=$(tput setaf 6)                  # dim cyan text
cyan="$bold$darkcyan"                     # bright cyan text
gray=$(tput setaf 7)                      # dim white text
darkgray="$bold"$(tput setaf 0)           # bold black = dark gray text
white="$bold$gray"                        # bright white text

#argument check
usage() {
    echo "${red}Usage: $0 <csv file name>${normal}"
    echo "${red}example: $0 test.csv${normal}"
    echo "${blue}csv file format: host mac mgmt_ip user password ipmi int1 int2 cimc sioc bmc${normal}"
    exit 1
}

if [ $# -ne 1 ]; then
   usage
   exit 1
fi

#check input and preinstall file.
[ ! -f $csvfile ] && { echo "$csvfile file not found"; exit 99;}
[ ! -f $preinstall ] && { echo "$preinstall file not found"; exit 99;}

#log function
echo_log(){
  LOG=pre.$1.log
  DATE=`date +%Y/%m/%d:%H:%M:%S`
  echo "$DATE $2" >> $LOG
}

#check csvfile
validate_csv() {
  LOG_FILE=pre.csv.log
  rm -rf $LOG_FILE
  count=$(head -1 $csvfile |awk -F"," '{print NF}')
  line=1

  echo "${blue}Validating $csvfile field counts ${normal}"
  echo_log csv "Validating $csvfile field counts"
  cat $csvfile |awk -F"," '{print NF}'|while read fc
  do
    if [ "$fc" != "$count" ];then
        echo "${red}ERROR: Line $line in $csvfile has incorrect field count${normal}"
        echo_log csv "${red}ERROR: Line $line in $csvfile has incorrect field count${normal}"
    fi
    line=$((line+1))
   done

 #quick check on logical fields
 echo "${blue}Quick test on $csvfile logical fields${normal}"
 echo_log csv "${blue}Quick test on $csvfile logical fields${normal}"
 #host mac mgmt_ip user password ipmi int1 int2 cimc sioc bmc
 line=2
   sed 1d $csvfile|while read host mac mgmt_ip user password ipmi int1 int2 cimc sioc bmc
   do
     if [ -z $host ];then
        echo "${red}Line $line in $csvfile is missing required host name field${normal}"
        echo_log csv "${red}ERROR: Line $line in $csvfile is missing required host name field${normal}"
        detect=$((detect+1))
      #cos465
      elif [ ! -z "$ipmi" ];then
           if  [ -z "$user" ] || [ -z "$password" ] || [ -z "$mac" ] || [ -z "$mgmt_ip" ] || [ -z "$int1" ] || [ -z "$int2" ];then
               echo "${red}Line $line in $csvfile $host missing required field detected for cos465${normal}"
               echo_log csv "${red}ERROR: Line $line in $csvfile $host missing required field detected for cos465${normal}"
               detect=$((detect+1))
           fi
       #cos3260
       elif [ ! -z "$cimc" ];then
            if  [ -z "$user" ] || [ -z "$password" ] || [ -z "$mac" ] || [ -z "$mgmt_ip" ] || [ -z "$int1" ] || [ -z "$int2" ] || [ -z "$sioc" ] || [ -z "$bmc" ] ;then
                echo "${red}Line $line in $csvfile $host missing required field detected for cos3260${normal}"
                echo_log csv "${red}ERROR: Line $line in $csvfile $host missing required field detected for cos3260${normal}"
                detect=$((detect+1))
             fi
       #cmc
       elif [[ $host =~ cmc ]];then
            if [ -z "$mac" ] || [ -z "$mgmt_ip" ];then
                echo "${red}Line $line in $csvfile $host missing required field detected for cmc${normal}"
                echo_log csv "${red}ERROR: Line $line in $csvfile $host missing required field detected for cmc${normal}"
                detect=$((detect+1))
            fi
       fi
       line=$((line+1))
   done

   if [ $(grep -i error $LOG_FILE|wc -l) -gt 0 ];then
      echo "${red}Problems detected in $csvfile, please correct the file and restart the script${normal}"
      echo_log csv "Problems detected in $csvfile, please correct the file and restart the script."
      echo_log csv "Check $LOG_FILE for additional detail"
      exit 99
   fi
}



#check for existing entry in inventory.yaml
check_duplicate() {
 hostname=$1
 if [ $(grep ^name $inventory|grep $hostname|wc -l) -gt 0 ]
 then
   echo "Yes"
 else
   echo "No"
 fi
}


#inventory configuration step.
cos465_config() {
#cos465_config $host $mac $mgmt_ip $user $password $ipmi $int1 $int2 &
 cos465_name="$1"
 cos465_mac="$2"
 cos465_mgmt_ip="$3"
 cos465_user="$4"
 cos465_password="$5"
 cos465_ipmi="$6"
 cos465_Data_eth4="$7"
 cos465_Data_eth5="$8"
 LOG_FILE=pre.$cos465_name.log
 rm -rf $LOG_FILE
 #call templates
 templates

#check for duplicate hostname in inventory.yaml
 while [ "$(check_duplicate $cos465_name)" == "Yes" ]
 do
    echo "${red}$cos465_name:Configuration Entry found in $inventory removing configuration${normal}"
    echo_log $cos465_name "${red}$cos465_name:Configuration Entry found in $inventory, removing configuration${normal}"
    clear_config $cos465_name
 done
 echo_log $cos465_name "$cos465_name:No duplicate entries found, continuing"

#add entry to inventory file
 echo_log $cos465_name "$cos465_name:adding entry onto the inventory file"
 printf "\n$cos465_template\n" >> $inventory
    if [ "$(sed -n "/^name: $cos465_name/,/^---/p" inventory.yml|wc -l)" != "13" ];then
       echo "${red}$cos465_name:the line count of the configuration does NOT match, please check the $inventory file${normal}"
       echo_log $cos465_name "${red}$cos465_name:the line count of the configuration does NOT match, please check the $inventory file${normal}"
       echo $(sed -n "/^name: $cos465_name/,/^---/p" inventory.yml|wc -l)
       exit 99
    fi
    #clean up empty line
    sed -i '/^$/d' $inventory
    echo "${green}$cos465_name:Configuration added to inventory successfully, continuing with ipmi${normal}"
    echo_log $cos465_name "${green}$cos465_name:Configuration added to inventory successfully, continuing with ipmi${normal}"

#ipmifunc $host $ipmi $user $password &
 echo_log $cos465_name "$cos465_name:iniating pre-vaquero step for ipmi"
 ipmifunc $cos465_name $cos465_ipmi $cos465_user $cos465_password &

#post verification step...
# ping -c 3 $cos465_mgmt_ip
}

cos3260_config(){
#cos3260_config $host $mac $mgmt_ip $user $password $int1 $int2 $cimc $sioc $bmc &
  cos3260_name="$1"
  cos3260_mac="$2"
  cos3260_mgmt_ip="$3"
  cos3260_user="$4"
  cos3260_password="$5"
  cos3260_Data_eth2="$6"
  cos3260_Data_eth3="$7"
  cos3260_cimc="$8"
  cos3260_sioc="$9"
  cos3260_bmc="${10}"

  LOG_FILE=pre.$cos3260_name.log
  rm -rf $LOG_FILE
#call templates
  templates

#check for duplicate hostname in inventory.yaml
 while  [ "$(check_duplicate $cos3260_name)" == "Yes" ]
 do
    echo "${red}$cos3260_name:Configuration Entry found in $inventory removing configuration${normal}"
    echo_log $cos3260_name "${red}$cos3260_name:Configuration Entry found in $inventory, removing configuration ${normal}"
    clear_config $cos3260_name
 done
 echo_log $cos3260_name "$cos3260_name:No duplicate entries found, continuing"

#add entry to inventory file
 echo_log $cos3260_name "$cos3260_name:adding entry onto the inventory file"
 printf "\n$cos3260_template\n" >> $inventory
    if [ "$(sed -n "/^name: $cos3260_name/,/^---/p" inventory.yml|wc -l)" != "13" ];then
       echo "${red}$cos3260_name:the line count of the configuration does NOT match, please check the $inventory file${normal}"
       echo_log $cos3260_name "${red}$cos3260_name:the line count of the configuration does NOT match, please check the $inventory file${normal}"
       echo $(sed -n "/^name: $cos3260_name/,/^---/p" inventory.yml|wc -l)
       exit 99
    fi
    #clean up empty lines
    sed -i '/^$/d' $inventory
    echo "${green}$cos3260_name:Configuration added to inventory successfully, continuing with cimc${normal}"
    echo_log $cos3260_name "${green}$cos3260_name:Configuration added to inventory successfully, continuing with cimc${normal}"

#cimcfunc $host $ipmi $user $password &
#$preinstall -c $cimc_ip -u $username -p ''"$cimc_password"'' -s $sioc_ip -b $bmc_ip
 echo_log $cos3260_name "$cos3260_name:initating pre-vaquero step for cimc"
 cimcfunc $cos3260_name $cos3260_cimc $cos3260_sioc $cos3260_bmc $cos3260_user $cos3260_password &
}


#cmc configuration
cmc_config() {
  cmc_name="$1"
  cmc_mac="$2"
  cmc_mgmt_ip="$3"
  LOG_FILE=pre.$cmc_name.log
  rm -rf $LOG_FILE
 #call templates
  templates

#check for duplicate hostname in inventory.yaml
 while [ "$(check_duplicate $cmc_name)" == "Yes" ]
 do
    echo "${red}$cmc_name:Configuration Entry found in $inventory, removing configuration${normal}"
    echo_log $cmc_name "${red}$cmc_name:Configuration Entry found in $inventory, removing configuration ${normal}"
    clear_config $cmc_name
 done
 echo_log $cmc_name "$cmc_name:No duplicate entries found, continuing"

#add entry to inventory file
 echo_log $cmc_name "$cmc_name:adding entry onto the inventory file"
 printf "\n$cmc_template\n" >> $inventory
    if [ "$(sed -n "/^name: $cmc_name/,/^---/p" inventory.yml|wc -l)" != "11" ];then
       echo "${red}$cmc_name:the line count of the configuration does NOT match, please check the $inventory file${normal}"
       echo_log $cmc_name "${red}$cmc_name:the line count of the configuration does NOT match, please check the $inventory file${normal}"
       echo $(sed -n "/^name: $cmc_name/,/^---/p" inventory.yml|wc -l)
       exit 99
    fi
    #clean up empty line
    sed -i '/^$/d' $inventory
    echo "${green}$cmc_name:Configuration added to inventory successfully, NEXT STEP?${normal}"
    echo_log $cmc_name "${green}$cmc_name:Configuration added to inventory successfully, NEXT STEP ? ${normal}"

#ipmifunc $host $ipmi $user $password &
# echo_log $cmc_name "$cmc_name:iniating pre-vaquero step for ipmi"
# ipmifunc $cmc_name $cmc_ipmi $cmc_user $cmc_password &

#post verification step...
# ping -c 3 $cmc_mgmt_ip

}



#pre-vaquero step
ipmifunc(){
   hostname=$1
   ipmi_ip="$2"
   user="$3"
   password="$4"
   LOG_FILE=pre.$hostname.log
#   rm -rf $LOG_FILE
   # set ipmi boot device
   echo_log $hostname "Starting ipmi configuration for $hostname, log will be $LOG_FILE"
   echo_log $hostname "Setting boot device to pxe"
   echo_log $hostname "/usr/bin/ipmitool -I lanplus -H $ipmi_ip -U $user -P $password chassis bootdev pxe"
   /usr/bin/ipmitool -I lanplus -H $ipmi_ip -U $user -P $password chassis bootdev pxe &>> $LOG_FILE
   status=`echo $?`
   if [ "$status" -ne "0" ];then
      echo ""
      echo "${red}$hostname: Error detected check $LOG_FILE${normal}"
      echo_log $hostname  "$hostname, Error detected check $LOG_FILE"
      exit 11
   fi

   echo_log $hostname "PXE boot setting successful, Rebooting"

   SYSTEM_STATUS=$(/usr/bin/ipmitool -I lanplus -H $ipmi_ip -U $user -P $password chassis status|grep "System Power"|awk -F':' '{print $2}')
   while [ "$SYSTEM_STATUS" == " on" ]
   do
     echo_log $hostname "System is on, shutting down"
     echo_log $hostname " /usr/bin/ipmitool -I lanplus -H $ipmi_ip -U $user -P $password chassis power off"
     /usr/bin/ipmitool -I lanplus -H $ipmi_ip -U $user -P $password chassis power off &>> $LOG_FILE
     sleep 8
     SYSTEM_STATUS=$(/usr/bin/ipmitool -I lanplus -H $ipmi_ip -U $user -P $password chassis status|grep "System Power"|awk -F':' '{print $2}')
   done

   echo_log $hostname "System Power off confirmed, Powering on the system"

   while [ "$SYSTEM_STATUS" != " on" ]
   do
     echo_log $hostname "System is off, powering on"
     /usr/bin/ipmitool -I lanplus -H $ipmi_ip -U $user -P $password chassis power on &>> $LOG_FILE
     sleep 8
     SYSTEM_STATUS=$(/usr/bin/ipmitool -I lanplus -H $ipmi_ip -U $user -P $password chassis status|grep "System Power"|awk -F':' '{print $2}')
   done
   echo ""
   echo "${green}$hostname: IPMI system reboot successful${normal}"
   echo_log $hostname "System Power on confirmed,IPMI system reboot successful"

}

#pre-vaquero step
cimcfunc() {
 hostname="$1"
 cimc_ip="$2"
 sioc_ip="$3"
 bmc_ip="$4"
 username="$5"
 cimc_password="$6"
 LOG_FILE=pre.$hostname.log
 rm -rf $LOG_FILE
#based on following command format.
#   /root/preinst_setup_UCSC-C3KIOE_2x10.sh -c 67.178.30.38 -u admin -b 67.178.30.36 -s 67.178.30.35 -p 'Comcast!23' -N
 echo_log $hostname "Starting preinstall script to $hostname"
 echo_log $hostname "$preinstall -c $cimc_ip -u $username -p '"$cimc_password"' -s $sioc_ip -b $bmc_ip -N"
   $preinstall -c $cimc_ip -u $username -p ''"$cimc_password"'' -s $sioc_ip -b $bmc_ip -N &>> $LOG_FILE

   while [ `grep -i "Logging out of" $LOG_FILE|wc -l` -eq 0 ]
   do
     echo_log $hostname "Monitoring status of the preinstall script for $hostname"
     if [  `grep -i error $LOG_FILE|wc -l` -gt 0 ]
     then
       echo ""
       echo "${red}$hostname: Error detected, please review the $LOG_FILE for details${normal}"
       echo_log $hostname "Error detected, please review the $LOG_FILE for details"
       exit 11
     fi
     sleep 20
   done

   echo ""
   echo "${green}$hostname: $preinstall script completed successfully${normal}"
   echo_log $hostname "$preinstall  script completed successfully for $hostname"

#post verification step...
# ping -c 3 $cos465_mgmt_ip
}

#remove cos465 from inventory
clear_config() {
 hostname="$1"
 echo_log $hostname "Removing $hostname from $inventory"
 echo "${blue}Removing $hostname configuration from $inventory${normal}"
 sed -i "/^name: $hostname/,/^---/d" $inventory
}


################
#   Main       #
################

#validate csvfile
validate_csv

#main loop to read in input file.
#sed 1d $csvfile|while read host ipmi cimc sioc bmc user password mac mgmt_ip eth2 eth3 eth4 eth5
sed 1d $csvfile|while read host mac mgmt_ip user password ipmi int1 int2 cimc sioc bmc
do
  #cos465
  if [ ! -z "$ipmi" ];then

     echo "${blue}$host, starting initial deployment${normal}"
     cos465_config $host $mac $mgmt_ip $user $password $ipmi $int1 $int2 &
  #cos3260
  elif [ ! -z "$cimc" ];then
     echo "${blue}$host, starting initial deployement${normal}"
   #     echo "${blue}$host, starting preinstall${normal}"
     if [ -z "$sioc" ];then
       sioc=$default_ip
     fi
     if [ -z "$bmc" ];then
       bmc=$default_ip
    fi
     cos3260_config $host $mac $mgmt_ip $user $password $int1 $int2 $cimc $sioc $bmc &
  #cimc
  elif [[ $host =~ cmc ]];then
     echo "${blue}$host, starting initial deployement${normal}"
     cmc_config $host $mac $mgmt_ip &

  fi
done
