#!/bin/env bash

RH_BASED=false
MAJOR_VERSION=0
CentMajor=0

# Tests if there is an /etc/redhat-release file.
# This applies to distributions based on Redhat, also.
if [ -f /etc/redhat-release ]
then
  RH_BASED=true
fi

if [[ $RH_BASED == true ]]
then
  # Handle it this way because different distributions have different numbers of spaces,
  # So using whitespace as delimiters won't work.
  # WARNING: This will blow up if there is a '.' in the file prior to the version number.
  MAJOR_VERSION=`awk 'BEGIN { FS = "." }; {print $1}' /etc/redhat-release | awk '{print $NF}'`
fi

if [[ $MAJOR_VERSION -ge 6 && $MAJOR_VERSION -lt 7 ]]
then
  echo "Do version 6 things."
elif [[ $MAJOR_VERSION -ge 7 && $MAJOR_VERSION -lt 8 ]]
then
  echo "Do version 7 things."
  # Install Java, wget, shasum, perl-Digest-SHA, and rpm
  # Commenting out some installs, to see what is really needed
  #yum -y update
  yum -y install java
  #yum -y install wget
  #yum -y install shasum
  #yum -y install perl-Digest-SHA
  yum -y install rpm
  
  # Prep Elasticsearch install
  cd /etc/yum.repos.d/
  elr='elasticsearch.repo'
  if [ -e $elr ]; then
    echo "File $elr already exists!"
  else
    echo "[elasticsearch-6.x]" >> $elr
    echo "name=Elasticsearch repository for 6.x packages" >> $elr 
    echo "baseurl=https://artifacts.elastic.co/packages/6.x/yum" >> $elr
    echo "gpgcheck=1" >> $elr
    echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch" >> $elr
    echo "enabled=1" >> $elr 
    echo "autorefresh=1" >> $elr
    echo "type=rpm-md" >> $elr
  fi  
  rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
  sudo yum install elasticsearch
  
  # Determine if this is CentOS 7
  CentMajor=$(cat /etc/centos-release | tr -dc '0-9.'|cut -d \. -f1)
else
  echo "Unhandled version $MAJOR_VERSION."
fi

if [[ $CentMajor -ge 7 && $CentMajor -lt 8 ]]
then
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
fi
