#!/bin/bash

set -euo pipefail

MIN_DOMAINS="${MIN_DOMAINS:-100}"

# Валидный домен: буквы/цифры/дефис, точки как разделители меток,
# ничего лишнего (кавычки, пробелы, спецсимволы — отсекаются).
DOMAIN_REGEX='^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$'

if [ ! -s hosts ]; then
  echo "::error::hosts file is empty or missing" >&2
  exit 1
fi

# Забираем ВСЕ поля после IP (а не только второе), на случай если
# в строке перечислено несколько доменов через пробел.
# Затем валидируем формат, убираем дубликаты и сортируем для стабильного diff.
mapfile -t domains < <(
  grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" hosts \
    | cut -d' ' -f2- \
    | tr ' \t' '\n' \
    | sed '/^$/d' \
    | grep -E "$DOMAIN_REGEX" \
    | sort -u
)

count="${#domains[@]}"
echo "Valid domains found: $count"

if [ "$count" -lt "$MIN_DOMAINS" ]; then
  echo "::error::only $count valid domains found (minimum $MIN_DOMAINS), aborting" >&2
  exit 1
fi

{
  echo '{'
  echo '  "version": 1,'
  echo '  "rules": ['
  echo '    {'
  echo '      "domain_suffix": ['
  for i in "${!domains[@]}"; do
    if [ "$i" -eq $((count - 1)) ]; then
      printf '        "%s"\n' "${domains[$i]}"
    else
      printf '        "%s",\n' "${domains[$i]}"
    fi
  done
  echo '      ]'
  echo '    }'
  echo '  ]'
  echo '}'
} > geohide.json

# Валидируем сам JSON перед компиляцией, чтобы получить понятную ошибку,
# а не невнятный сбой от sing-box
python3 -m json.tool geohide.json > /dev/null

sing-box rule-set compile geohide.json -o geohide.srs

rm -f geohide.json
