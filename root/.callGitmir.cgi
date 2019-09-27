#!/usr/bin/perl
print "Content-type: text/html\n\n";
print "Hello, World.";
exec "bash /gitmir/gitmir.sh -f /gitmir/feederFile.json";
