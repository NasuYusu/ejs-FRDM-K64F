#!/bin/bash

cat OBC/bits_obc.txt > obc_contents.h
cat OBC/string_bits.txt > preload_strings.h
echo ok bitops-bits-in-byte.obc
make
