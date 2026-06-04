#!/bin/bash

#THIS SCRIPT REQUIRES BASH ON enicspulp01
while [[ $(netstat -antp | grep '8989' | wc -l) -lt 1 ]]; do
    echo $(netstat -antp | grep '8989')
    sleep 1
done
path=$(readlink -f $PULP_ENV/src/ips/riscv/tb/dm/sansa_compliance.cfg)
#"Why don't I use $HOSTNAME here?", I expect the next person who reads this will ask themselves.
#Well, becuase vmanager likes to play with environment variables, it sometimes overwrites
#the local value for $HOSTNAME with the server's value.
host=$(hostname)
ssh enicspulp01 "export SIM_HOST=$host; export SIM_PORT=8989; openocd -f $path"
