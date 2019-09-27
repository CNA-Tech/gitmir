#!/bin/bash
export GITMIRROOT
chmod +x /gitmir/gitmir.sh
/gitmir/gitmir.sh -f /gitmir/feederFile.json | tee /gitmir/gitmirlog
wait
httpd-foreground