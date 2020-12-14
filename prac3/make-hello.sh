#!/bin/bash

main_file=$1
exe_file=~/public_html/practica3/hello.cgi

test -d ~/public_html/practica3 || mkdir -p ~/public_html/practica3
source ~WEBprofe/usr/share/bin/do-make-exe.sh
