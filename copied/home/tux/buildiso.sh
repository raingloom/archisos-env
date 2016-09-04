#!/bin/sh
set -x
if [ $USER != tux ]; then
	su -c $0 tux
else
	/home/tux/repo/releng/fullbuild.sh -v
fi
