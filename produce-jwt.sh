#!/bin/bash
#
# Description:
# This script creates an JWT 
# Using the base64 command for encoding
#

# error function
function error(){
  echo "Error: The file $1 was not found."
  exit 1
}

# replace a string in an existing file
function replaceVar(){
  VAR1="$1"
  VAR2="$2"
  FILE="$3"
  CMD="perl -pi -e 's|${VAR1}|${VAR2}|g' $FILE"
  eval $CMD
}

# variables
TMP_DIR="./tmp"
CONF_DIR="conf"
PRODUCER_CONF="$CONF_DIR/jwt/producer/producer.conf"
HEADER_TEMPLATE="$CONF_DIR/jwt/producer/header.template"
PAYLOAD_TEMPLATE="$CONF_DIR/jwt/producer/payload.template"
DLT_CONF="$CONF_DIR/dlt/producer/wallet.conf"

# create temporary directory
[ -d "$TMP_DIR" ] || mkdir -p $TMP_DIR

# read configuration file(s)
[ -r "$PRODUCER_CONF" ] || error "$PRODUCER_CONF"
. $PRODUCER_CONF
[ -r "$DLT_CONF" ] || error "$DLT_CONF"
. $DLT_CONF

# verify DLT support
if [ $DLT != "namecoin" ]; then 
  echo "$DLT is not supported"
  exit 1
fi

# create message
[ -r "$HEADER_TEMPLATE" ] && cp $HEADER_TEMPLATE $TMP_DIR/header || error "$HEADER_TEMPLATE"
[ -r "$PAYLOAD_TEMPLATE" ] && cp $PAYLOAD_TEMPLATE $TMP_DIR/payload || error "$PAYLOAD_TEMPLATE"
replaceVar "ALGORITHM" ${ALGORITHM} $TMP_DIR/header
replaceVar "ISSUER" "${ISSUER}" $TMP_DIR/payload
replaceVar "DLT" "${DLT}" $TMP_DIR/payload
replaceVar "DSN" "${DSN}" $TMP_DIR/payload
if [ -z "$EXPIRYDATE" ]; then
    now=$(date +%s)
    expiry_date=$(( ${now} + ${MINUTES} * 60 ))
    replaceVar "EXPIRYDATE" "${expiry_date}" $TMP_DIR/payload
else
    replaceVar "EXPIRYDATE" "${EXPIRYDATE}" $TMP_DIR/payload
fi
header=$(cat $TMP_DIR/header)
payload=$(cat $TMP_DIR/payload)
message=$header.$payload 
echo $message > $TMP_DIR/message

# get address value from NMC
nshow=$(namecoin-cli -datadir=$NMC_DATA_DIR name_show "$ISSUER")
wallet_address=$(echo $nshow | python -c "import sys, json; print json.load(sys.stdin)['address']")
echo $wallet_address > $TMP_DIR/wallet_address

# unlock wallet for n seconds
namecoin-cli -datadir=$NMC_DATA_DIR walletpassphrase "${NMC_WALLET_PWD}" $NMC_UNLOCK_SEC &>/dev/null

# sign message
signature=$(namecoin-cli -datadir=$NMC_DATA_DIR signmessage "${wallet_address}" "${message}") 

# create unencoded_token
unencoded_token="$message.$signature"
echo $unencoded_token > $TMP_DIR/unencoded_token

# create access_token 
enc="$(echo -n "$header" | base64 | tr -d '\n')"
enc="$enc.$(echo "$payload" | base64 | tr -d '\n')"
enc="$enc.$(echo "$signature" | base64 | tr -d '\n')"
echo $enc > $TMP_DIR/access_token

# print access_token
cat $TMP_DIR/access_token

exit 0
