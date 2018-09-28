#!/bin/env bash

# The TinyURL is:  https:// tinyurl [dot] com/C7VMAutoDeploy 
# TinyURL preview is: https://preview [dot] tinyurl [dot] com/C7VMAutoDeploy
# This script includes the commands from 'get_rh_version.sh', created by Jaydeehow (https://github.com/Jaydeehow/Bash)
ACVversion="2018-09-28-1224"
echo "Going home"
cd /home/
SCRIPTDATE=`date +"%Y%m%d-%H%M%S"`
#script "script_auto_conf_vm_$SCRIPTDATE.log" # script was causing the script to stop
pwd
whoami
echo "Running auto_conf_vm.sh version $ACVversion"

# Declare variables
RH_BASED=false
MAJOR_VERSION=0
CentMajor=0
configSSH=false
installElastic=false
installKibana=false
installLogstash=false

# Prompt for sshd configuration
echo "Will sshd be configured?"
select yn in "Yes" "No"; do
    case $yn in
        'Yes') configSSH=true; break;;
        'No') break;;
        *) echo "You fail, respond to the question..";;
    esac
done

# Prompt for Elasticsearch installation
echo "Will Elasticsearch be installed?"
select yn in "Yes" "No"; do
    case $yn in
        'Yes') installElastic=true; break;;
        'No') break;;
        *) echo "You fail, respond to the question..";;
    esac
done

# Prompt for Kibana installation
echo "Will Kibana be installed?"
select yn in "Yes" "No"; do
    case $yn in
        'Yes') installKibana=true; break;;
        'No') break;;
        *) echo "You fail, respond to the question..";;
    esac
done

# Prompt for Logstash installation
echo "Will Logstash be installed?"
select yn in "Yes" "No"; do
    case $yn in
        'Yes') installLogstash=true; break;;
        'No') break;;
        *) echo "You fail, respond to the question..";;
    esac
done

# Tests if there is an /etc/redhat-release file.
# This applies to distributions based on Redhat, also.
if [ -f /etc/redhat-release ]; then
  RH_BASED=true
fi # end of: if [ -f /etc/redhat-release ]

if [[ $RH_BASED == true ]]; then
  # Handle it this way because different distributions have different numbers of spaces,
  # So using whitespace as delimiters won't work.
  # WARNING: This will blow up if there is a '.' in the file prior to the version number.
  MAJOR_VERSION=`awk 'BEGIN { FS = "." }; {print $1}' /etc/redhat-release | awk '{print $NF}'`
fi # end of: if [[ $RH_BASED == true ]]

if [[ $MAJOR_VERSION -ge 6 && $MAJOR_VERSION -lt 7 ]]
then
  echo "Do version 6 things."
elif [[ $MAJOR_VERSION -ge 7 && $MAJOR_VERSION -lt 8 ]]
then
  echo "Do version 7 things."
  
  if $configSSH == true; then
    # Make a backup of the default sshd_config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
  
    SSH_Port=""
    while [[ ! $number =~ ^[0-9]+$ ]]; do
      echo "Please enter the port for SSH: "; read SSH_Port
    done
    echo "You have specified port number $SSH_Port"
    # Create a new user, for future use
    #echo "Please enter the new user name: "; read New_Username
    #echo $New_Username
    #echo "Please enter the password for $New_Username: "; read -s New_Userpass
    #echo "Password received"
  fi # end of: if $configSSH == true
  
  # Update yum, this is only suggested for lab systems!!
  # yum -y update # This is for the lab system only, do not use in production!
  if ! which java; then
    # Install Java
    yum -y install java
  fi # end of: if ! which java
  
  # Install open-vm-tools on a Virtual Machine
  if dmidecode | grep -i vmware; then
    echo "This is a VMware Virtual Machine, checking for open-vm-tools"
    if ! which open-vm-tools; then
      echo "installing open-vm-tools"
      yum -y install open-vm-tools
      systemctl enable vmtoolsd.service
      systemctl start vmtoolsd
      echo "open-vm-tools has been installed and started"
    fi # end of: if ! which open-vm-tools
  fi # end of: if dmidecode | grep -i vmware
  
  # Prep Elasticsearch install
  rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
  
  cd /etc/yum.repos.d/
  elr='elasticsearch.repo'
  if [ -e $elr ]; then
    echo "File $elr already exists"
  else
    echo "Creating file $elr and populating it with 6.x info" #Provide feedback
    echo "[elasticsearch-6.x]" >> $elr
    echo "name=Elasticsearch repository for 6.x packages" >> $elr 
    echo "baseurl=https://artifacts.elastic.co/packages/6.x/yum" >> $elr
    echo "gpgcheck=1" >> $elr
    echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch" >> $elr
    echo "enabled=1" >> $elr 
    echo "autorefresh=1" >> $elr
    echo "type=rpm-md" >> $elr
    echo "Populated $elr with data" #Provide feedback
  fi # end of: if [ -e $elr ]
  cd /home/
  
  if $installElastic == true; then
    # Install Elasticsearch and make a copy of the original config file
    yum -y install elasticsearch
    cd /etc/elasticsearch/
    cp elasticsearch.yml elasticsearch.yml.backup
    echo "Elasticsearch config needs to be updated, path is /etc/elasticsearch/elasticsearch.yml"
    systemctl enable elasticsearch.service
    cd /home/
  fi # end of: if ! which elasticsearch
  
  if $installKibana == true; then
    # Install Kibana and make a copy of the original config file
    yum -y install kibana
    cd /etc/kibana/
    cp kibana.yml kibana.yml.backup
    echo "Kibana config needs to be updated, path is /etc/kibana/kibana.yml"
    systemctl enable kibana.service
    cd /home/
  fi # end of: if ! which kibana
  
  if $installLogstash == true; then
    # Install Logstash and make a copy of the original config file
    yum -y install logstash
    cd /etc/logstash/
    cp logstash.yml logstash.yml.backup
    echo "Logstash config needs to be updated, path is /etc/logstash/logstash.yml"
    systemctl enable logstash.service
    cd /home/
  fi # end of: if ! which logstash
  
  # Determine if this is CentOS 7
  CentMajor=$(cat /etc/centos-release | tr -dc '0-9.'|cut -d \. -f1)
else
  echo "Unhandled version $MAJOR_VERSION."
fi # end of: if [[ $MAJOR_VERSION -ge 6 && $MAJOR_VERSION -lt 7 ]]


# CentOS 7 minimal has the firewall enabled, we need to open default ports
# This section is separate from the RedHat major version for this reason.
if [[ $CentMajor -ge 7 && $CentMajor -lt 8 ]]; then
  # This needs to be updated to account for the version listed above.
  # This also needs to be moved into the section to perform version 7 actions
  echo "Performing automated system configuration for CentOS 7, assuming CentOS 7 (minimal)"
  
  if $installElastic == true; then
    # open default ports for Elasticsearch
    firewall-cmd --zone=public --add-port=9200/tcp --permanent
    firewall-cmd --zone=public --add-port=9200/udp --permanent
    echo "Default ports opened in the public zone for Elasticsearch"
    firewall-cmd --zone=public --add-service=Elasticsearch --permanent
    echo "Elasticsearch service has been added to the public zone"
    #systemctl restart firewalld
    systemctl reload firewalld
  fi # end of: if $installElastic == true
  
  if $installKibana == true; then
    # open default ports for Kibana
    firewall-cmd --zone=public --add-port=5601/tcp --permanent
    firewall-cmd --zone=public --add-port=5601/udp --permanent
    echo "Default ports opened in the public zone for Kibana"
    firewall-cmd --zone=public --add-service=Kibana --permanent
    echo "Kibana service has been added to the public zone"
    #systemctl restart firewalld
    systemctl reload firewalld
  fi # end of: if $installKibana == true
  
  # Check sshd_config
  if which sshd; then
    # Check PermitEmptyPasswords
    if grep -Eq '^PermitEmptyPasswords +[yY][eE][sS]' /etc/ssh/sshd_config; then
      echo "PermitEmptyPasswords should be set to no";
    elif grep -Eq '^PermitEmptyPasswords +[nN][oO]' /etc/ssh/sshd_config; then
      echo "PermitEmptyPasswords meets requirements";
    fi
    # Check PermitRootLogin
    if grep -Eq '^PermitRootLogin +[yY][eE][sS]' /etc/ssh/sshd_config; then
      echo "PermitRootLogin should be set to no";
    elif grep -Eq '^PermitRootLogin +[nN][oO]' /etc/ssh/sshd_config; then
      echo "PermitRootLogin meets requirements";
    fi
    
    echo "sshd_config still needs to be updated before enabling and starting sshd"
  fi # end of: if which sshd
  
  echo "Services still need to be configured and enabled before starting"
  
fi # end of: if [[ $CentMajor -ge 7 && $CentMajor -lt 8 ]]

exit # Close the script file
