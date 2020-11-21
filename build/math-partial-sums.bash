#!/bin/bash

cat OBC/sums_obc.txt > obc_contents.h
cat OBC/string_sums.txt > preload_strings.h
echo ok math-partial-sums.obc
make
