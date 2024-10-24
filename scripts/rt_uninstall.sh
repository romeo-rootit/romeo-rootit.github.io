#!/bin/bash

echo "Removing ROOT IT Support Account"
userdel rootit > /dev/null 2>&1
rm -rf /home/rootit/ > /dev/null 2>&1
rm /etc/ssh/rootit_tunnel_key > /dev/null 2>&1
rm /etc/sudoers.d/rootit
