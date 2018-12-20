#!/bin/sh

if [ "${1:0:1}" = "-" ]; then
  set -- /atheme/bin/atheme-services -n "$@"
fi

exec "$@"
