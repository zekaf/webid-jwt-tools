#!/bin/bash
#
# Compare TLS certificate fingerprint
#

# chech arguments
if [ $# -ne 2 ]; then
  echo
  echo "Invalid number of arguments."
  echo "Usage: ./$(basename "$0") <host:port> <fingerprint>"
  echo
  echo "Example:"
  echo "./$(basename "$0") gnu.org:443 6307935568EB7218B6171BF7785C2B8D9C0B4E95"
  echo
  exit 1
fi


HOST_PORT="$1"
FPRINT_1="$2"

FPRINT_0=$(echo | openssl s_client -connect $HOST_PORT |& openssl x509 -fingerprint -noout | cut -f2 -d'=')
FPRINT_0="${FPRINT_0//:}"
FPRINT_1="${FPRINT_1//:}"

if [ "$FPRINT_0" == "$FPRINT_1" ]; then
    echo true
    exit 0
  else
    echo false
    exit 1
fi
