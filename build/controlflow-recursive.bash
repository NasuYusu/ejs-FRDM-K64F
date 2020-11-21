#!/bin/bash

cat OBC/recursive_obc.txt > obc_contents.h
cat OBC/string_recursive.txt > preload_strings.h
echo ok controlflow-recursive.obc
make
