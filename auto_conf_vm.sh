#!/bin/env bash

# The TinyURL is:  https://preview [dot] tinyurl [dot] com/C7VMAutoDeploy
# This script includes the commands from 'get_rh_version.sh', created by Jaydeehow (https://github.com/Jaydeehow/Bash)
RH_BASED=false
MAJOR_VERSION=0
CentMajor=0

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
  # Update yum, this is only suggested for lab systems!!
  yum -y update # This is for the lab system only, do not use in production!
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
  
  if ! which elasticsearch; then
    # Install Elasticsearch and make a copy of the original config file
    yum -y install elasticsearch
    cd /etc/elasticsearch/
    cp elasticsearch.yml elasticsearch.yml.backup
    echo "The elasticsearch.yml file needs to be updated here"
  fi # end of: if ! which elasticsearch
  
  if ! which kibana; then
    # Install Kibana and make a copy of the original config file
    yum -y install kibana
    cd /etc/kibana/
    cp kibana.yml kibana.yml.backup
    echo "The kibana.yml file needs to be updated here"
  fi # end of: if ! which kibana
  
  if ! which logstash; then
    # Install Logstash and make a copy of the original config file
    yum -y install logstash
    cd /etc/logstash/
    cp logstash.yml logstash.yml.backup
    echo "The logstash.yml file needs to be updated here"
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
  # open default ports for Elasticsearch
  firewall-cmd --zone=public --add-port=9200/tcp --permanent
  firewall-cmd --zone=public --add-port=9200/udp --permanent  
  # open default ports for Kibana
  firewall-cmd --zone=public --add-port=5601/tcp --permanent
  firewall-cmd --zone=public --add-port=5601/udp --permanent
  echo "Default ports allowed for Elasticsearch and Kibana"
fi # end of: if [[ $CentMajor -ge 7 && $CentMajor -lt 8 ]]
