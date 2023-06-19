#! /usr/bin/sh

if [ "$#" -ne 1 ]; then
  echo must specify either work or personal setup
  exit 1
fi

source ./shared/bootstrap.sh
source ./$1/bootstrap.sh