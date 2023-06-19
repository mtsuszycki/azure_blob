#!/bin/bash

# List the blobs in an Azure storage container.

[ $# -ne 3 ] && echo "usage: ${0##*/} <storage-account-name> <container-name> <access-key>"

storage_account="$1"
container_name="$2"
access_key="$3"

blob_store_url="blob.core.windows.net"
authorization="SharedKey"

request_method="GET"

action=put

request_date=$(TZ=GMT date "+%a, %d %h %Y %H:%M:%S %Z")
storage_service_version="2011-08-18"

# HTTP Request headers
x_ms_date_h="x-ms-date:$request_date"
x_ms_version_h="x-ms-version:$storage_service_version"

# Build the signature string
canonicalized_headers="${x_ms_date_h}\n${x_ms_version_h}"
canonicalized_resource="/${storage_account}/${container_name}"

string_to_sign="${request_method}\n\n\n\n\n\n\n\n\n\n\n\n${canonicalized_headers}\n${canonicalized_resource}\ncomp:list\nrestype:container"

[ $action == 'put' ] && {
string_to_sign="PUT https://${storage_account}.${blob_store_url}/${container_name}/rawlogs/michaltest
\n\n\n\n\n\n\n\n\n\n\n\n${canonicalized_headers}\n${canonicalized_resource}\ncomp:list\nrestype:container"
put_header='x-ms-blob-content-disposition: attachment; filename="michaltest"'
put_header1='Content-Length: 11'
}


# Decode the Base64 encoded access key, convert to Hex.
decoded_hex_key="$(echo -n $access_key | base64 -d -w0 | xxd -p -c256)"

# Create the HMAC signature for the Authorization header
#signature=$(echo -n "$string_to_sign" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$decoded_hex_key" | sed 's/^.*= //' | base64 -w0)
signature=$(printf "$string_to_sign" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$decoded_hex_key" -binary |  base64 -w0)

authorization_header="Authorization: $authorization $storage_account:$signature"

echo  "$x_ms_date_h" "$x_ms_version_h" "$authorization_header" 

curl \
  -H "$x_ms_date_h" \
  -H "$x_ms_version_h" \
  -H "$authorization_header" \
  -H "$put_header" \
  -d "hello world"	\
  "https://${storage_account}.${blob_store_url}/${container_name}?restype=container&comp=list"

 
