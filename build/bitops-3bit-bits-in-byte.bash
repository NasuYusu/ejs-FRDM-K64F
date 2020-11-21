#!/bin/bash

cat OBC/3bit_obc.txt > obc_contents.h
cat OBC/string_3bit.txt > preload_strings.h
echo ok bitops-3bit-bits-in-byte.obc
make
