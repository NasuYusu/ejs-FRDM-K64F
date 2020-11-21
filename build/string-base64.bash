#!/bin/bash

cat OBC/base64_obc.txt > obc_contents.h
cat OBC/string_base64.txt > preload_strings.h
echo ok string-base64.obc
make
