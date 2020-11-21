#!/bin/bash

cat OBC/fasta_obc.txt > obc_contents.h
cat OBC/string_fasta.txt > preload_strings.h
echo ok stirng-fasta.obc
make
