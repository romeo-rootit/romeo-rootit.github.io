#!/bin/bash
# GNU/Linux reverse tunnel setup

echo "ROOT IT Reverse Tunnel Script
Licensed GPLv3
https://www.gnu.org/licenses/gpl-3.0.en.html"

# Ensure that sshd is installed
# Be intelligent about different distros
if [ -z "$(which sshd)" ]; then
  echo "installing sshd..."
  if command -v yum &> /dev/null; then
    yum install -y openssh-server > /dev/null 2>&1
  elif command -v dnf &> /dev/null; then
    dfn install -y openssh-server > /dev/null 2>&1
  elif command -v zypper &> /dev/null; then
    zypper install -y openssh > /dev/null 2>&1
  elif command -v apt &> /dev/null; then
    apt update > /dev/null 2>&1
    apt install -y openssh-server > /dev/null 2>&1
  elif command -v pacman &> /dev/null; then
    pacman -Sy --noconfirm openssh > /dev/null 2>&1
  else
    echo "No supported package manager found."
    exit 1
  fi
fi

# Ensure that sshd is running
# Debian-based distros call it ssh.service and everyone else calls it sshd.service
# Debian-based distros used to provide an alias but stopped doing that recently
if command -v apt > /dev/null; then
  systemctl start ssh > /dev/null 2>&1
else
  systemctl start sshd > /dev/null 2>&1
fi

USERNAME="rootit"
if ! getent passwd ${USERNAME} > /dev/null ; then
  # Create user for login and set password
  PWHASH='$6$kVgsrnpdfAA4oXLJ$Jda5ekMu/XS.lEaYbzWBKA9RXKo7/xag/6BUPUO65PlpKPj7Ae17HDGe0.pRpzqkWUO6l52LHhPmxJh3ApQld0'
  useradd "${USERNAME}" --shell /bin/bash
  echo "${USERNAME}:${PWHASH}" | chpasswd -e
  mkhomedir_helper ${USERNAME}
  # Set SSH key
  USERHOMEDIR="$(getent passwd ${USERNAME} | cut -d ':' -f 6)"
  USERSSHDIR="${USERHOMEDIR}/.ssh/"
  mkdir "${USERSSHDIR}"
  echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII58SfewaHZEyr1kmQcImuKPVS8VoMXvvdJQDP/y20aH" > "${USERSSHDIR}/authorized_keys"
  chown -R ${USERNAME} "${USERSSHDIR}"
  chmod -R go-rwx "${USERSSHDIR}"
  # Add to sudoers
  echo "rootit ALL=(ALL) ALL" > /etc/sudoers.d/rootit
  chmod o-rwx /etc/sudoers.d/rootit
fi

# Set up key for reverse tunnel jiggery pokery
TUNNELKEY="/etc/ssh/rootit_tunnel_key"
if [ ! -f ${TUNNELKEY} ]; then
  echo "-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACClKObO1MLLM5FHCD0ogMoei9ld3PdYl0sQehUVGgTTKgAAAKhyqVMacqlT
GgAAAAtzc2gtZWQyNTUxOQAAACClKObO1MLLM5FHCD0ogMoei9ld3PdYl0sQehUVGgTTKg
AAAEBsBsATUgWGfb7k2xCLnZKr9L4W0aVWEBgdt92Ofzx8Q6Uo5s7UwsszkUcIPSiAyh6L
2V3c91iXSxB6FRUaBNMqAAAAHmJlZXBlckBsYXB0b3AuaGVqbW8ucHVua3RvLm9yZwECAw
QFBgc=
-----END OPENSSH PRIVATE KEY-----" > ${TUNNELKEY}
  chmod go-rwx ${TUNNELKEY}
  chown rootit ${TUNNELKEY}
fi

# Create reverse tunnel
# Choose a random port number. Very unlikely to have duplicates
TUNNELHOST="tunnel.rootit.org"
TUNNELHOST_PORT="523"
TUNNELUSER="tunneluser"
if [ -z "${1}" ]; then
  LOCAL_PORT='22'
else
  LOCAL_PORT="${1}"
fi
if ! ps -ef | grep "${TUNNELKEY}" | grep -v grep > /dev/null; then
  RANDOM_PORT=$((2000 + RANDOM % (65535 - 2000 + 1)))
  echo -e '\n\n\n\n'
  echo "Port number is ${RANDOM_PORT}. Please give this number to ROOT IT support."
  sudo -u ${USERNAME} ssh -i ${TUNNELKEY} -o StrictHostKeyChecking=no ${TUNNELUSER}@${TUNNELHOST} -p ${TUNNELHOST_PORT} -N -R "${RANDOM_PORT}:localhost:${LOCAL_PORT}" 2> /dev/null
fi
