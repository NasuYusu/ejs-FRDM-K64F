#!/bin/bash

FILENAME=$1
OBC=${FILENAME%.*}

if [ "$2" = "--32bit" ]; then
  java -jar ejsc.jar --out-obc --out-bit32 $1 -o ${OBC}.obc > preload_strings.h
else
  java -jar ejsc.jar --out-obc $1 -o ${OBC}.obc > preload_strings.h
fi
od -v -t x1 ${OBC}.obc | sed -e 's/^[0-9][0-9]* */0x/' | sed -e 's/ *$/,/'| sed -e's/  */, 0x/g'| sed '$d' | sed '$s/,$//' > obc_contents.h

make
