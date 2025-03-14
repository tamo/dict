#!/bin/sh
# Public domain

tr -d '\t\r\n 　'  | \
sed -e 's,<TRclass=.><TD>[0-9]*</TD><TD>\(.\)</TD><TD>\([^&]*\)&nbsp\;</TD></TR>,\n\1\2,g' | \
sed -e '1d;/^A/,$d' | \
while read line; do
  for i in $(seq 1 ${#line}); do
    char="$(echo $line | cut -c $i)"
    others="${line:0:$(($i-1))}${line:$i}"

    output="$char /"
    for j in $(seq 1 ${#others}); do
      output="$output$(echo $others | cut -c $j)/"
    done
    echo "$output"
  done
done

