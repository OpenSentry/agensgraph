#!/bin/sh

/bin/ag_ctl -D /data -l /logs/server.log start

exec "$@"
