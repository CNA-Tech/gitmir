#!/bin/bash
export GITMIRROOT
bash /gitmir/gitmir.sh -f /gitmir/feederFile.json | tee /gitmir/gitmirlog
wait
httpd-foreground
