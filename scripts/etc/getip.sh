#!/bin/bash

getip(){
ip addr | grep inet | grep -v "127.0.0.1" | grep -v inet6 | awk '{print $2}' | sed 's/\/[0-9]*$//'
}

getip
