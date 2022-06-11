#!/bin/bash

# This apt-get waits until lock is released
# https://github.com/geerlingguy/packer-boxes/issues/7#issuecomment-425641793
function apt-get() { 
  while fuser -s /var/lib/apt/lists/lock;
  do echo 'apt-get is waiting for the lock release ...';
      sleep 1;
  done;
  /usr/bin/apt-get "$@";
}
