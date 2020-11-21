#!/bin/bash

cat OBC/binary-trees_obc.txt > obc_contents.h
cat OBC/string_binary-trees.txt > preload_strings.h
echo ok access-binary-trees.obc
make
