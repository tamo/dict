#!/bin/bash
# Public domain

while read line; do
  length=${#line}
  [ $length -lt 2 ] && continue
  for i in $(seq 0 $(($length-1))); do
    char="${line:$i:1}"
    others="${line:0:$i}${line:$(($i+1))}"

    output="$char /"
    for j in $(seq 0 $(($length-2))); do
      output="$output${others:$j:1}/"
    done
    echo "$output"
  done
done

