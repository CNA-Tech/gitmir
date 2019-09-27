#!/usr/bin/perl
print "Content-type: text/html\n\n";
print "Hello, World.";
system("/bin/bash /gitmir/initGitmirLocalCall.sh");
print "Goodbye, World.";