#!/bin/bash
if test -f "runeday.json"; then
  PREVIOUS=$(jq '.lastConfigUpdateRuneday' runeday.json)
else
  PREVIOUS=0
fi

curl -s https://secure.runescape.com/m=itemdb_rs/api/info.json --output runeday.json
CURRENT=$(jq '.lastConfigUpdateRuneday' runeday.json)

if ((PREVIOUS < CURRENT)); then
  echo "Time to run" >> test.log
else
  echo "Nothing to do" >> test.log
fi