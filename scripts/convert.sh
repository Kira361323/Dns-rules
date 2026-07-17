#!/bin/bash

set -euo pipefail

MIN_DOMAINS="${MIN_DOMAINS:-100}"

# Валидный домен: буквы/цифры/дефис, точки как разделители меток
DOMAIN_REGEX='^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$'

if [ ! -s hosts_geo ] || [ ! -s hosts_malw ]; then
  echo "::error::One or both source files are empty or missing" >&2
  exit 1
fi

# Склеиваем оба файла, фильтруем, удаляем \r, валидируем и отсекаем дубли
mapfile -t domains < <(
  cat hosts_geo hosts_malw \
    | grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" \
    | cut -d' ' -f2- \
    | tr ' \t' '\n' \
    | tr -d '\r' \
    | sed '/^$/d' \
    | grep -E "$DOMAIN_REGEX" \
    | sort -u
)

count="${#domains[@]}"
echo "Valid unique domains found: $count"

if [ "$count" -lt "$MIN_DOMAINS" ]; then
  echo "::error::Only $count valid domains found (minimum $MIN_DOMAINS), aborting" >&2
  exit 1
fi

# Мгновенный дамп массива в JSON
{
  echo '{'
  echo '  "version": 1,'
  echo '  "rules": ['
  echo '    {'
  echo '      "domain_suffix": ['
  printf '        "%s",\n' "${domains[@]}" | sed '$ s/,$//'
  echo '      ]'
  echo '    }'
  echo '  ]'
  echo '}'
} > domains.json

# Проверка синтаксиса перед компиляцией
python3 -m json.tool domains.json > /dev/null

# Сборка бинарного файла для sing-box
sing-box rule-set compile domains.json -o domains.srs

rm -f domains.json
