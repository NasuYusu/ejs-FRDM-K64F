#!/bin/bash

cat OBC/nsieve_obc.txt > obc_contents.h
cat OBC/string_nsieve.txt > preload_strings.h
echo ok access-nsieve.obc
make
