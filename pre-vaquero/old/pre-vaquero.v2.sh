#!/bin/bash
#
# version = 2.0
# Cisco AS Services, kerhee@cisco.com
# 
# 1.0 basic error check implemented with session limit
# 2.0 use default ip for sioc and bmc if none is provided for cos3260 
#
#######################################################################
csvfile=$1
preinstall="./preinst_setup_UCSC-C3KIOE_2x10.sh"
default_ip="1.1.1.1"
IFS=,
ulimit -u 50

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

usage() {
    echo "${red}Usage: $0 <csv file name>${normal}"
    echo "${red}example: $0 test.csv${normal}"
    echo "${blue}csv file format: host,ipmi,cimc,sioc,bmc,user,password${normal}"
    exit 1
}

if [ $# -ne 1 ]; then
   usage
   exit 1
fi

#check input and preinstall file.
[ ! -f $csvfile ] && { echo "$csvfile file not found"; exit 99;}
[ ! -f $preinstall ] && { echo "$preinstall file not found"; exit 99;}

echo_log(){
  LOG=pre.$1.log
  DATE=`date +%Y/%m/%d:%H:%M:%S`
  echo "$DATE $2" >> $LOG
}

ipmifunc(){
   hostname=$1
   ipmi_ip="$2"
   user="$3"
   password="$4"
   LOG_FILE=pre.$hostname.log
   rm -rf $LOG_FILE
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
}


#main loop to read in input file.
sed 1d $csvfile|while read host ipmi cimc sioc bmc user password 
do
  if [ -z "$ipmi" ];then
     echo "${blue}$host, starting preinstall${normal}"
     if [ -z "$sioc" ];then
       sioc=$default_ip
     fi 
     if [ -z "$bmc" ];then
       bmc=$default_ip
     fi
     cimcfunc $host $cimc $sioc $bmc $user $password & 
  else 
     echo "${blue}$host, starting ipmi${normal}"
     ipmifunc $host $ipmi $user $password & 
  fi
done 

