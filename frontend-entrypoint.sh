#!/bin/bash

if [ "$#" == 0 ]
then
  yarn install

  ember server
else
  exec $@
fi
