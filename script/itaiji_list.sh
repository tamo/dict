#!/bin/bash
# Public domain

while read line; do
  [ ${#line} -lt 2 ] && continue
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

