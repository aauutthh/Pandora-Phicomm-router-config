#!/bin/sh
# dropbearkey -f yy -t rsa -s 2048
port=20022
VPSPORT=22000
VPSUSER=root
localip=`/sbin/ip addr show dev br-lan |grep -o "inet [0-9.]*"|awk '{print $2}'`
p=`ps |grep "ssh -p ${VPSPORT}"|grep $port|wc -l`
cmd="/usr/bin/ssh -p ${VPSPORT} -i /root/${VPSIP}.id_rsa -fNR *:${port}:${localip}:22 ${VPSUSER}@${VPSIP}"
date > /tmp/sshlog.txt
if [ $p -eq 0 ] ; then
  ps |grep "ssh -p ${VPSPORT}"|grep ${port}|awk '{print $2}'|xargs kill -9
  echo run $cmd >> /tmp/sshlog.txt
  $cmd >>/tmp/sshlog.txt &
fi

