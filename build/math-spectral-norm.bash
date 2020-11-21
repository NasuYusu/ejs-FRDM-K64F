#!/bin/bash

cat OBC/norm_obc.txt > obc_contents.h
cat OBC/string_norm.txt > preload_strings.h
echo ok math-spectral-norm.obc
make
