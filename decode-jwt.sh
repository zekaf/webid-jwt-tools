#!/bin/bash
#
# Decode JWT and validate signature
# Using the Linux Bash base64 command and the jq utility
# (JSON processor for shell) https://stedolan.github.io/jq/
#

function error(){
  code=$1
  [ $code -eq 1 ] && echo "File not found."
  [ $code -eq 2 ] && echo "Wrong number of JWT elements ($elements)"
  exit 1
}

FILE1="access_token"

# Read the access token
[ -f $FILE1 ] && access_token=$(cat $FILE1) || error 1

# Stripping the JWT parts Header.Payload.Signature into an array
declare -a jwt
IFS='.' read -r -a jwt <<< "$access_token"

elements="${#jwt[@]}"
[ $elements -ne 3 ] && error 2

# Print the jwt array
#for index in "${!jwt[@]}"
#do
#    echo "$index ${jwt[index]}"
#done

header=$(echo "${jwt[0]}" | base64 -d)
payload=$(echo "${jwt[1]}" |base64 -d)
signature=$(echo "${jwt[2]}" | base64 -d)
message="$header.$payload"

echo "$header.$payload.$signature"
