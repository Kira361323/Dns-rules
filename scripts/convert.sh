#!/bin/bash

set -e

cat > geohide.json <<EOF
{
  "version": 1,
  "rules": [
    {
      "domain_suffix": [
EOF


grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" hosts \
| awk '{print $2}' \
| sed '/^$/d' \
| sed 's/^/        "/;s/$/",/' \
>> geohide.json


sed -i '$ s/,$//' geohide.json


cat >> geohide.json <<EOF
      ]
    }
  ]
}
EOF


sing-box rule-set compile geohide.json -o geohide.srs