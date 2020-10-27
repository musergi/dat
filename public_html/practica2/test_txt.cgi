#!/bin/sh

# disable filename globbing
set -f

echo "Content-Type: text/plain"
echo

echo "<!doctype html>"
echo "<html><head>"
echo "<meta charset='utf-8'>"
echo "<title>CGI que d&oacute;na l'hora...</title>"
echo "</head><body>"
echo "<h1>Avui &eacute;s "
date "+%A %d de %B del %Y"
echo "</h1>"
echo "<h1>I s&oacute;n les "
date "+%T"
echo "</h1>"
echo "</body></html>"
