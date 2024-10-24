#!/bin/bash
#

echo "Remove ROOT IT support account? [y/N]"
read choice1
if [ "${choice1}" == "y" ]; then
  userdel rootit
  rm -rf /home/rootit/
  rm /etc/ssh/rootit_tunnel_key
fi

echo "Remove SSH server? [y/N]"
read choice2
if [ "${choice2}" == "y" ]; then
  apt purge -y openssh-server
  systemctl stop ssh
fi
