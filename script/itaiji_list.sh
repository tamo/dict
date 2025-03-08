#!/bin/sh
# Public domain

tr -d '\t\r\n 　'  | \
sed -e 's,<TRclass=.><TD>[0-9]*</TD><TD>\(.\)</TD><TD>\([^&]*\)&nbsp\;</TD></TR>,\n\1\2,g' | \
sed -e '1d;/^A/,$d' | \
while read line; do
  for i in $(seq 1 ${#line}); do
    char=$(echo "$line" | cut -c "$i")
    others=$(echo "$line" | sed "s/$char//")
    printf "%s /%s\\n" "$char" "$(echo "$others" | sed 's/./&\//g')"
  done
done

