#!/bin/bash

cat OBC/bitwise_obc.txt > obc_contents.h
cat OBC/string_bitwise.txt > preload_strings.h
echo ok bitops-bitwise-and.obc
make
