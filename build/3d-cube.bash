#!/bin/bash

cat OBC/3d_obc.txt > obc_contents.h
cat OBC/string_3d.txt > preload_strings.h
echo ok 3d-cube.obc
make
