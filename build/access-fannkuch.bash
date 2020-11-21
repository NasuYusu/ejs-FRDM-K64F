#!/bin/bash

cat OBC/fannkuch_obc.txt > obc_contents.h
cat OBC/string_fannkuch.txt > preload_strings.h
echo ok access-fannkuch.obc
make
