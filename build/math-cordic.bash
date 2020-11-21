#!/bin/bash

cat OBC/cordic_obc.txt > obc_contents.h
cat OBC/string_cordic.txt > preload_strings.h
echo ok math-cordic.obc
make
