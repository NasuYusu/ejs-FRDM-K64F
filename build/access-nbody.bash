#!/bin/bash

cat OBC/nbody_obc.txt > obc_contents.h
cat OBC/string_nbody.txt > preload_strings.h
echo ok access-nbody.obc
make
