#!/bin/bash

cat OBC/validate_obc.txt > obc_contents.h
cat OBC/string_validate.txt > preload_strings.h
echo ok string-validate-input.obc
make
